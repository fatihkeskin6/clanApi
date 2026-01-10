import csv
from datetime import datetime, timezone

from app.db_conn import get_conn


def main():
    with open("./clan_sample_data.csv", "r", encoding="utf-8") as file:
        reader = csv.DictReader(file)

        with get_conn() as conn:
            with conn.cursor() as cur:
                inserted = 0

                for row in reader:
                    name = row.get("name")
                    region = row.get("region")

                    if not name or not region:
                        continue

                    name = name.strip()
                    region = region.strip().upper()

                    created_at = row.get("created_at")

                    if created_at:
                        try:
                            created_at = created_at.replace("Z", "+00:00")
                            created_at = datetime.fromisoformat(created_at)
                        except Exception:
                            created_at = datetime.now(timezone.utc)

                        cur.execute(
                            """
                            INSERT INTO clans (name, region, created_at)
                            VALUES (%s, %s, %s);
                            """,
                            (name, region, created_at),
                        )
                    else:
                        cur.execute(
                            """
                            INSERT INTO clans (name, region)
                            VALUES (%s, %s);
                            """,
                            (name, region),
                        )

                    inserted += 1

            conn.commit()

    print("Inserted rows:", inserted)


if __name__ == "__main__":
    main()
