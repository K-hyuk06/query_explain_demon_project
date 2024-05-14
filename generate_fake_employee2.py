from faker import Faker
import csv
import datetime

fake = Faker()
fake.seed_instance(100)
names = [fake.unique.first_name() for i in range(500)]
dates = [
    datetime.date(2024, 5, 5).strftime("%Y-%m-%d"),
    datetime.date(2024, 5, 6).strftime("%Y-%m-%d"),
    datetime.date(2024, 5, 7).strftime("%Y-%m-%d"),
]

with open("./employee2.csv", "w", newline="") as csvfile:
    writer = csv.writer(csvfile, delimiter=",")
    writer.writerow(["emp_id", "name", "work_date"])

    for i in range(len(names)):
        writer.writerow([i + 1, names[i], dates[0]])
        writer.writerow([i + 1, names[i], dates[1]])
        writer.writerow([i + 1, names[i], dates[2]])
