from azure.identity import ManagedIdentityCredential
from azure.storage.blob import BlobServiceClient
import os

def upload_blob_with_managed_identity(
    storage_account_name: str,
    container_name: str,
    blob_name: str,
    local_file_path: str,
    managed_identity_client_id: str = None
):

    # Create the MI credential
    credential = ManagedIdentityCredential(client_id=managed_identity_client_id)

    # Storage account URL
    account_url = f"https://{storage_account_name}.blob.core.windows.net"

    # Blob service client using Managed Identity
    blob_service_client = BlobServiceClient(account_url=account_url, credential=credential)

    # Get container client
    container_client = blob_service_client.get_container_client(container_name)

    # Ensure container exists (optional)
    try:
        container_client.create_container()
    except Exception:
        pass  # Container probably already exists

    # Upload file
    with open(local_file_path, "rb") as data:
        container_client.upload_blob(name=blob_name, data=data, overwrite=True)

    print(f"Uploaded '{local_file_path}' → {container_name}/{blob_name}")


if __name__ == "__main__":
    # Example usage
    upload_blob_with_managed_identity(
        storage_account_name="dorinh12363",
        container_name="mycontainer",
        blob_name="example.txt",
        local_file_path="example.txt",
        # For system-assigned MI, leave this as None
        managed_identity_client_id=None  
    )
