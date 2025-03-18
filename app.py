import qdrant_client
from fastapi import FastAPI
from fastembed import SparseEmbedding
from pydantic import BaseModel
from qdrant_client.models import (
    Distance,
    NamedSparseVector,
    SearchRequest,
    SparseIndexParams,
    SparseVector,
    SparseVectorParams,
    VectorParams,
)

import create_embeddings as ce

# https://blog.futuresmart.ai/building-an-async-similarity-search-system-from-scratch-with-fastapi-and-qdrant-vectordb


class QueryRequest(BaseModel):
    query_string: str  # The search query entered by the user
    limit: int  # The number of search results to return


collection_name = "PDFs"


# Initialize Qdrant client
qdrant = qdrant_client.AsyncQdrantClient("http://localhost:6333")


# Create collection in Qdrant vector database
async def create_qdrant_collection():
    exist = await qdrant.collection_exists(collection_name=collection_name)
    if not exist:
        await qdrant.create_collection(
            collection_name,
            vectors_config={
                "text-dense": VectorParams(
                    size=1024,
                    distance=Distance.COSINE,
                )
            },
            sparse_vectors_config={
                "text-sparse": SparseVectorParams(
                    index=SparseIndexParams(
                        on_disk=False,
                    )
                )
            },
        )


async def qdrant_search(query: str, limit: int):
    query_sparse_vectors: list[SparseEmbedding] = ce.make_sparse_embedding([query])

    search_results = await qdrant.search_batch(
        collection_name=collection_name,
        requests=[
            SearchRequest(
                vector=NamedSparseVector(
                    name="text-sparse",
                    vector=SparseVector(
                        indices=query_sparse_vectors[0].indices.tolist(),
                        values=query_sparse_vectors[0].values.tolist(),
                    ),
                ),
                limit=limit,
                with_payload=True,
            ),
        ],
    )
    print(search_results[0])

    results = [
        {
            "id": res.id,
            "page": res.payload["page"],
            "source": res.payload["source"],
            "text": res.payload["text"],
            "score": res.score,  # Semantic similarity score
        }
        for res in search_results[0]
    ]

    return results


# FastAPI lifecycle event to initialize Qdrant
async def async_lifespan(app: FastAPI):
    await create_qdrant_collection()  # Ensures the Qdrant collection exists
    yield  # Yield control, FastAPI will now handle incoming requests


app = FastAPI(lifespan=async_lifespan)


@app.get("/")
async def read_root():
    return {"message": "Hello, Qdrant!"}


@app.post("/document")
async def create_document(page: ce.Page):
    points = ce.create_points(page)

    batch_size = 1000

    for i in range(0, len(points), batch_size):
        batch = points[i : i + batch_size]
        response = await qdrant.upsert(collection_name, batch)

    return {"response": response}


@app.post("/semantic_search")
async def search(query: QueryRequest):
    results = await qdrant_search(query.query_string, query.limit)
    return {"results": results}
