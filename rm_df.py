# %%
import pandas as pd

# %%
df = pd.read_csv("./AmazonSaleReport.csv")


# %%
print(df.columns)
# %%

df.drop(
    columns=[
        "index",
        "ship-city",
        "ship-state",
        "ship-postal-code",
        "ship-country",
        "promotion-ids",
        "ship-service-level",
        "Sales Channel ",
        "fulfilled-by",
        "Unnamed: 22",
    ],
    axis=1,
    inplace=True,
)

# %%
df.head()
df.to_csv("./AmazonSaleReport2.csv", index=False)
# %%
