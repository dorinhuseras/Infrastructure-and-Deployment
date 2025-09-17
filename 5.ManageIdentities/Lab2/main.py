import os, uuid
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient


class AuthSamples(object):
    # <Snippet_get_service_client_DAC>
    def get_blob_service_client_token_credential(self):
        # TODO: Replace <storage-account-name> with your actual storage account name
        account_url = "https://<storage-account-name>.blob.core.windows.net"
        credential = DefaultAzureCredential()

        # Create the BlobServiceClient object
        blob_service_client = BlobServiceClient(account_url, credential=credential)

        return blob_service_client
    # </Snippet_get_service_client_DAC>

    # <Snippet_upload_blob_file>
    def upload_blob_file(self, blob_service_client: BlobServiceClient, container_name: str):
        container_client = blob_service_client.get_container_client(container=container_name)
        with open(file=os.path.join('./', 'file3.txt'), mode="rb") as data:
            blob_client = container_client.upload_blob(name="sample-blob3.txt", data=data, overwrite=True)
    # </Snippet_upload_blob_file>


if __name__ == '__main__':
    sample = AuthSamples()
    container_name = ""
    blob_service_client = sample.get_blob_service_client_token_credential()

    sample.upload_blob_file(blob_service_client, container_name)