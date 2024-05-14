from faker import Faker
import csv

fake = Faker()
fake.seed_instance(100)
names = [fake.unique.first_name() for i in range(500)]

with open("./employee1.csv", "w", newline="") as csvfile:
    writer = csv.writer(csvfile, delimiter=",")
    writer.writerow(["emp_id", "name"])
    for i in range(len(names)):
        writer.writerow([i + 1, names[i]])
