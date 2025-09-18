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

    # <Snippet_get_service_client_SAS>
    def get_blob_service_client_sas(self, sas_token: str):
        # TODO: Replace <storage-account-name> with your actual storage account name
        account_url = "https://<storage-account-name>.blob.core.windows.net"
        # The SAS token string can be assigned to credential here or appended to the account URL
        credential = sas_token

        # Create the BlobServiceClient object
        blob_service_client = BlobServiceClient(account_url, credential=credential)

        return blob_service_client
    # </Snippet_get_service_client_SAS>

    # <Snippet_get_service_client_account_key>
    def get_blob_service_client_account_key(self):
        # TODO: Replace <storage-account-name> with your actual storage account name
        account_url = "https://<storage-account-name>.blob.core.windows.net"
        shared_access_key = ""
        credential = shared_access_key

        # Create the BlobServiceClient object
        blob_service_client = BlobServiceClient(account_url, credential=credential)

        return blob_service_client
    # </Snippet_get_service_client_account_key>

    # <Snippet_get_service_client_connection_string>
    def get_blob_service_client_connection_string(self):
        # TODO: Replace <storage-account-name> with your actual storage account name
        account_url = "https://<storage-account-name>.blob.core.windows.net"
        connection_string = ""

        # Create the BlobServiceClient object
        blob_service_client = BlobServiceClient.from_connection_string(connection_string)

        return blob_service_client
    # </Snippet_get_service_client_connection_string>

    # <Snippet_upload_blob_file>
    def upload_blob_file(self, blob_service_client: BlobServiceClient, container_name: str):
        container_client = blob_service_client.get_container_client(container=container_name)
        with open(file=os.path.join('./', 'file3.txt'), mode="rb") as data:
            blob_client = container_client.upload_blob(name="sample-blob3.txt", data=data, overwrite=True)
    # </Snippet_upload_blob_file>


if __name__ == '__main__':
    sample = AuthSamples()
    container_name = ""
    #blob_service_client = sample.get_blob_service_client_token_credential()
    #blob_service_client = sample.get_blob_service_client_sas(sas_token='')
    #blob_service_client = sample.get_blob_service_client_account_key()
    #blob_service_client = sample.get_blob_service_client_connection_string()

    sample.upload_blob_file(blob_service_client, container_name)