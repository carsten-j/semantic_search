import os
from typing import Any, Dict, Iterable

import polars as pl
from fastembed import SparseEmbedding, SparseTextEmbedding
from langchain_community.document_loaders import PyMuPDFLoader
from langchain_core.documents.base import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from pydantic import BaseModel
from qdrant_client.models import (
    PointStruct,
    SparseVector,
)


class Page(BaseModel):
    page_content: str
    metadata: Dict[str, Any]


class Pages(BaseModel):
    documents: list[Page]


def read_pdfs(rootdir: str) -> list[Document]:
    docs = []
    for subdir, _, files in os.walk(rootdir):
        for file in files:
            if file.endswith(".pdf"):
                file_path = os.path.join(subdir, file)
                print(file_path)
                loader = PyMuPDFLoader(
                    file_path=file_path,
                    mode="page",
                )
                docs_lazy = loader.lazy_load()
                for doc in docs_lazy:
                    docs.append(doc)
    return docs


def create_chunks(
    docs: Iterable[Document],
) -> list[Document]:
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=512, chunk_overlap=0, add_start_index=True
    )
    chunks = text_splitter.split_documents(docs)
    return chunks


sparse_model_name = "Qdrant/bm25"
sparse_model = SparseTextEmbedding(model_name=sparse_model_name, batch_size=32)


def make_sparse_embedding(texts: list[str]) -> list[SparseEmbedding]:
    return list(sparse_model.embed(texts, batch_size=256))


def create_dataframe(
    chunks: Iterable[Document],
) -> pl.DataFrame:
    rows = []

    for chunk in chunks:
        text = chunk.page_content
        embeddings = make_sparse_embedding([text])
        rows.append(
            {
                "text": text,
                "source": chunk.metadata["source"],
                "page_label": chunk.metadata["page"],
                "sparse_embedding_values": embeddings[0].values,
                "sparse_embedding_indices": embeddings[0].indices,
            }
        )

    df = pl.DataFrame(rows)
    return df


def make_points(df: pl.DataFrame) -> list[PointStruct]:
    points = []
    idx = 1
    for row in df.iter_rows(named=True):
        sparse_vector = SparseVector(
            indices=row["sparse_embedding_indices"].tolist(),
            values=row["sparse_embedding_values"].tolist(),
        )
        point = PointStruct(
            id=idx,
            payload={
                "page": row["page_label"],
                "source": row["source"],
                "text": row["text"],
            },
            vector={
                "text-sparse": sparse_vector,
            },
        )
        points.append(point)
        idx += 1
    return points


def _create_points(pages: list[Pages]) -> list[PointStruct]:
    docs = []
    for page in pages:
        docs.append(Document(page_content=page.page_content, metadata=page.metadata))
    chunks = create_chunks(docs)
    df = create_dataframe(chunks)
    points = make_points(df)
    return points


def create_points(page: Page) -> list[PointStruct]:
    docs = Document(page_content=page.page_content, metadata=page.metadata)
    chunks = create_chunks([docs])
    df = create_dataframe(chunks)
    points = make_points(df)
    return points
