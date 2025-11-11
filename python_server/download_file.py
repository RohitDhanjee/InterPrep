# import requests
# import os
# from urllib.parse import unquote, urlparse


# def download_file(url):
#     parsed_url = urlparse(unquote(url))
#     path = parsed_url.path
#     file_name = os.path.basename(path)
#     _, file_extension = os.path.splitext(file_name)
#     file_extension = file_extension.lstrip('.')

#     local_directory = r"D:\projects\FYP\interprep\python_server"
#     local_file_path = os.path.join(local_directory, file_name)

#     if os.path.exists(local_file_path):
#         os.remove(local_file_path)

#     response = requests.get(url, stream=True)
#     if response.status_code == 200:
#         with open(local_file_path, 'wb') as f:
#             for chunk in response.iter_content(chunk_size=8192):
#                 f.write(chunk)
#         return local_file_path, file_extension
#     else:
#         return None, None


import requests
import os
from urllib.parse import unquote, urlparse


def download_file(url):
    parsed_url = urlparse(unquote(url))
    path = parsed_url.path
    file_name = os.path.basename(path)
    _, file_extension = os.path.splitext(file_name)
    file_extension = file_extension.lstrip('.')

    # --- Directory Management ---
    local_directory = r"D:\projects\FYP\interprep\python_server"
    
    # 1. Ensure the directory exists. This is the crucial fix.
    os.makedirs(local_directory, exist_ok=True) 
    # ----------------------------
    
    local_file_path = os.path.join(local_directory, file_name)

    if os.path.exists(local_file_path):
        os.remove(local_file_path)

    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(local_file_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        return local_file_path, file_extension
    else:
        # It's helpful to print the error status if the download fails
        print(f"DEBUG: Failed to download {file_name}. HTTP Status: {response.status_code}")
        return None, None