from pathlib import Path


class BaseReader:
    """
    Base class for all readers.
    """

    def __init__(self, file_path: Path):
        self.file_path = file_path

    def read(self):
        pass

class CSVReader(BaseReader):
    """
    Reader for CSV files.
    """

    def read(self):
        return pd.read_csv(self.file_path)