import os
import glob
from google.cloud import bigquery
from google.oauth2 import service_account

# Credentials are hidden, this file wont be executed anymore just to show you how did I upload existing sample_data I received to BigQuery as RAW data.
PROJECT_ID = "***"
DATASET_ID = "***"          
TABLE_ID = "user_level_daily_metrics"
LOCATION = "europe-west1"

DATA_DIR = './data/'
SERVICE_ACCOUNT_FILE = r"./***.json"
CONTINUE_ON_ERROR = True


def get_client():
    creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE,
        scopes=["https://www.googleapis.com/auth/cloud-platform"],
    )
    return bigquery.Client(project=PROJECT_ID, credentials=creds)


def ensure_dataset(client: bigquery.Client):
    ds = bigquery.Dataset(f"{PROJECT_ID}.{DATASET_ID}")
    ds.location = LOCATION
    try:
        client.get_dataset(ds)
        print(f"Dataset exists: {PROJECT_ID}.{DATASET_ID}")
    except Exception:
        client.create_dataset(ds)
        print(f"Dataset created: {PROJECT_ID}.{DATASET_ID} (location={LOCATION})")


def load_files():
    client = get_client()
    ensure_dataset(client)

    table_fqdn = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"

    files = sorted(glob.glob(os.path.join(DATA_DIR, "*.csv.gz")))
    if not files:
        raise RuntimeError(f"No .csv.gz files found under: {DATA_DIR}")

    print(f"Found {len(files)} files. Loading into {table_fqdn}")

    for i, path in enumerate(files, start=1):
        write_disposition = (
            bigquery.WriteDisposition.WRITE_TRUNCATE
            if i == 1
            else bigquery.WriteDisposition.WRITE_APPEND
        )

        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            autodetect=True,
            skip_leading_rows=1,
            write_disposition=write_disposition,
            allow_quoted_newlines=True,
        )

        print(f"[{i}/{len(files)}] {os.path.basename(path)} -> {write_disposition}")

        try:
            with open(path, "rb") as f:
                job = client.load_table_from_file(
                    f,
                    destination=table_fqdn,
                    job_config=job_config,
                    location=LOCATION,
                    rewind=True,
                    timeout=600,
                )


            job.result()
            print(f"done, rows loaded: {job.output_rows}")

        except Exception as e:
            print(f" fail on file: {os.path.basename(path)}")
            print(f" error: {e}")
            if not CONTINUE_ON_ERROR:
                raise

    # log
    tbl = client.get_table(table_fqdn)
    print("\n LOAD COMPLETED3213213213213312")
    print(f"Table: {tbl.project}.{tbl.dataset_id}.{tbl.table_id}")
    print(f"Rows:  {tbl.num_rows}")
    print(f"Size:  {tbl.num_bytes / (1024**2):.2f} MB")


if __name__ == "__main__":
    load_files()
