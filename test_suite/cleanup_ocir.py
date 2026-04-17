# Remove all the containers and the OCIR repositories of the compartment TF_VAR_compartment_ocid
#
# Usage: 
#   export TF_VAR_compartment_ocid=xxx
#   python3 cleanup_ocir.py
#
import os
import oci
from oci.pagination import list_call_get_all_results

def main():
    compartment_ocid = os.environ.get("TF_VAR_compartment_ocid")
    if not compartment_ocid:
        raise ValueError("TF_VAR_compartment_ocid environment variable is not set")

    # Load OCI config (default profile)
    config = oci.config.from_file()
    artifacts_client = oci.artifacts.ArtifactsClient(config)

    print(f"Fetching repositories in compartment: {compartment_ocid}")

    # List all container repositories
    repos = list_call_get_all_results(
        artifacts_client.list_container_repositories,
        compartment_ocid=compartment_ocid
    ).data

    if not repos:
        print("No repositories found.")
        return

    for repo in repos:
        print(f"\nProcessing repository: {repo.display_name} ({repo.id})")

        # List all image versions in the repository
        images = list_call_get_all_results(
            artifacts_client.list_container_images,
            compartment_ocid=compartment_ocid,
            repository_id=repo.id
        ).data

        for image in images:
            print(f"  Deleting image version: {image.id}")
            try:
                artifacts_client.delete_container_image(image.id)
            except Exception as e:
                print(f"    Failed to delete image {image.id}: {e}")

        # After deleting images, delete the repository
        print(f"  Deleting repository: {repo.display_name}")
        try:
            artifacts_client.delete_container_repository(repo.id)
        except Exception as e:
            print(f"    Failed to delete repository {repo.id}: {e}")

    print("\nDone.")


if __name__ == "__main__":
    main()