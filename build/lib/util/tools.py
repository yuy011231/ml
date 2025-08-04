import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd

def correlation_heatmap(df: pd.DataFrame):
    """
    Plot a correlation heatmap of the dataframe.
    """
    fig, axs = plt.subplots(figsize=(10, 8))
    sns.heatmap(df.corr(),annot=True)
    plt.show()