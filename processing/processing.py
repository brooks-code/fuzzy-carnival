#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# =============================================================================
# File name: processing.py
# Author: FRBNF11934724
# Date created: 2025-04-15
# Date modified: 2025-04-25
# Version = "1.0.1"
# License =  "The Unlicense"
# =============================================================================
""" Gather and process the dailyword's project source datasets."""
# =============================================================================


# Imports
import os
from urllib.parse import urlsplit
import re
import requests
import pandas as pd
import ast
import unicodedata
from typing import Tuple, Dict, Any


# Parameters
# Directories and file paths
PROCESSING_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(PROCESSING_DIR, 'processing_data')
SOURCE_DATASETS_DIR = os.path.join(DATA_DIR, 'source_datasets')

# Create directories if they don't exist.
os.makedirs(SOURCE_DATASETS_DIR, exist_ok=True)
os.makedirs(DATA_DIR, exist_ok=True)

# URLs and file names
LEXIQUE_URL: str = 'http://www.lexique.org/databases/Lexique383/Lexique383.tsv'
DICO_URL: str = 'https://github.com/Kartmaan/french-language-tools/raw/refs/heads/master/files/dico.csv'

# Extract filenames from URLs
LEXIQUE_FILE: str = os.path.basename(urlsplit(LEXIQUE_URL).path)
DICO_FILE: str = os.path.basename(urlsplit(DICO_URL).path)

OUTPUT_FILE: str = os.path.join(DATA_DIR, 'daily_words.csv')

FREQ_THRESHOLD: float = 0.4

# For definitions cleaning
CLEANING_REGEX = re.compile(r'["$$$$]')
LOWVALUE_PATTERN = re.compile(
    r'pluriel|action d|in singulier d|inin d|du verbe|qualité d|caractère d|celui,\s*celle|celui qu|celle qu|fait d|'
    r'individu qui|personne qui|qui peut être|qui a rapport|qui se rapporte|qui concerne|relatif (?:à|a)"|état de|'
    r'opposition à|qui cherche|ce qui est|variante (?:d|ortho)|quelque chose|quelqu\'un qui|[rm]e personne d',
    flags=re.IGNORECASE
)


# ---------------------------------------------------------------------------
# Functions

def download_file(url: str, filename: str) -> None:
    """
    Download a file in chunks from a URL and save its content to the provided filename.

    Args:
    - url: The URL to download the file from.
    - filename: The local file path where the downloaded file will be stored.
    """
    try:
        with requests.get(url, stream=True) as response:
            response.raise_for_status()
            with open(filename, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
        print(f"Downloaded file: {filename}")
    except requests.exceptions.RequestException as e:
        print("Error downloading file:", e)


def check_and_load_data(lexique_file: str, dico_file: str) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """
    Load data from Lexique and Dico files. If the files do not exist in the
    source_datasets folder, they are downloaded.

    Args:
    - lexique_file: The filename for the Lexique data (TSV file).
    - dico_file: The filename for the Dico data (CSV file).

    Returns:
    A tuple containing:
    - lexique_df: DataFrame loaded from the Lexique file with columns renamed.
    - dico_df: DataFrame loaded from the Dico file.
    """
    lexique_path: str = os.path.join(SOURCE_DATASETS_DIR, lexique_file)
    if not os.path.exists(lexique_path):
        print(f"{lexique_path} not found. Downloading...")
        download_file(LEXIQUE_URL, lexique_path)
    lexique_df: pd.DataFrame = pd.read_csv(lexique_path, sep='\t')
    lexique_df.rename(
        columns={'ortho': 'mot', 'phon': 'phonétique'}, inplace=True)

    dico_path: str = os.path.join(SOURCE_DATASETS_DIR, dico_file)
    if not os.path.exists(dico_path):
        print(f"{dico_path} not found. Downloading...")
        download_file(DICO_URL, dico_path)
    dico_df: pd.DataFrame = pd.read_csv(dico_path)
    dico_df.rename(columns={'Définitions': 'définitions'}, inplace=True)
    return lexique_df, dico_df


def filter_lexique_and_calculate_custom_freq_index(df: pd.DataFrame) -> pd.DataFrame:
    """
    Filter the Lexique DataFrame to include only noun entries that satisfy
    specific constraints and calculate a synthetic score (weighted average) based on different frequency indexes.
    Frequencies are per million.

    Args:
    - df: The Lexique DataFrame containing lexical information.

    Returns:
    A new DataFrame grouped by 'mot', 'genre', 'lemme', 'phonétique' with averaged synthetic scores.
    """
    mask = (df['cgram'] == 'NOM') & (
        df['nombre'] != 'p') & (df['mot'].str.len() >= 4)
    filtered_df: pd.DataFrame = df.loc[mask].copy()

    weight_lemlivres: int = 3
    weight_livres: int = 3

    filtered_df['custom_freq_index'] = (
        filtered_df['freqlemfilms2'] +
        filtered_df['freqfilms2'] +
        weight_lemlivres * filtered_df['freqlemlivres'] +
        weight_livres * filtered_df['freqlivres']
    ) / (2 + weight_lemlivres + weight_livres)
    filtered_df['custom_freq_index'] = filtered_df['custom_freq_index'].round(
        3)

    # Group by relevant keys and average the custom frequency score.
    grouped_df: pd.DataFrame = filtered_df.groupby(
        ['mot', 'genre', 'lemme', 'phonétique'], dropna=False
    )['custom_freq_index'].mean().reset_index()
    return grouped_df


def merge_dataframes(dico_df: pd.DataFrame, lexique_df: pd.DataFrame) -> pd.DataFrame:
    """
    Merge the Lexique and Dico DataFrames using a common key in lowercase.

    Args:
    - dico_df: DataFrame containing dictionary data including definitions.
    - lexique_df: DataFrame containing Lexique data and synthetic frequencies scores.

    Returns:
    The merged DataFrame.
    """
    lexique_df['mot_lexique_lower'] = lexique_df['mot'].str.lower()
    dico_df['Mot_dico_lower'] = dico_df['Mot'].str.lower()

    merged_df: pd.DataFrame = pd.merge(
        lexique_df, dico_df,
        left_on='mot_lexique_lower',
        right_on='Mot_dico_lower',
        how='inner'
    )

    merged_df.drop(['mot_lexique_lower', 'Mot_dico_lower'],
                   axis=1, inplace=True)
    return merged_df


def remove_low_value_sentence(definition):
    # Split on the delimiter '|'
    sentences = [s.strip() for s in definition.split("|")]
    # Filter out any sentence that contains a low-value pattern.
    filtered = [
        s for s in sentences if not LOWVALUE_PATTERN.search(s)]
    # Re-join the chunks with ' | ' if any remain; otherwise return an empty string.
    return " | ".join(filtered) if filtered else ""


def clean_and_process_definitions(df: pd.DataFrame) -> pd.DataFrame:
    """
    Clean and process definitions by:
      - Filtering entries based on the custom frequency score.
      - Converting string representations of lists (in the 'définitions' column) into joined strings.
      - Removing duplicate definitions.
      - Performing vectorized string cleaning to by removing unwanted characters and separate multiple definition in case of polysemia.
      - Filtering out low lexical value definitions based on a regex match.


    Args:
    - df: DataFrame containing 'custom_freq_index' and 'définitions' columns.

    Returns:
    A DataFrame with processed definitions.
    """
    df = df[df['custom_freq_index'] <= FREQ_THRESHOLD].copy()
    # Convert the definitions only once
    df['définitions'] = df['définitions'].apply(ast.literal_eval)
    # Combine lists into a joined string
    df['définitions'] = df['définitions'].apply(lambda lst: ' | '.join(lst))

    # Remove duplicate definitions
    df['définitions'] = df['définitions'].apply(
        lambda s: " | ".join(dict.fromkeys(s.split(" | "))))

    # Perform vectorized cleaning operations
    df['définitions'] = df['définitions'].str.replace(
        CLEANING_REGEX, '', regex=True)
    df['définitions'] = df['définitions'].str.replace(r'\.,', ' |', regex=True)
    df['définitions'] = df['définitions'].str.replace(
        r"(?<!\w)'(?!\w)", "", regex=True)

    # Filter out low content definitions by sentences
    df = (df.assign(définitions=df['définitions']
                    .apply(remove_low_value_sentence)
                    .str.strip())
          .query("définitions != ''"))

    # Filter out definitions (older more conservative method)
    # keeps low content if more than one definition present (contains a |)
    # cond = df['définitions'].str.contains(
    #    LOWVALUE_PATTERN, na=False) & ~df['définitions'].str.contains('\\|', na=False)
    # df = df.loc[~cond].copy()

    df = df[df['définitions'].str.len() > 3]

    return df


def update_feminine_definitions(df: pd.DataFrame) -> pd.DataFrame:
    """
    Update feminine definitions with their corresponding masculine definitions based on the 'lemme' 
    key to ensure a parity in definition completeness (since in many cases, feminine definitions
     do not provide the definition but only refer to the masculine one).

    Intent: correct a bias in the Dico dataset.

    Args:
    - df: DataFrame containing 'genre', 'lemme', and 'définitions' columns.

    Returns:
    A DataFrame with updated definitions.
    """
    masculine_defs: Dict[Any, Any] = df[df['genre'] == 'm'].set_index('lemme')[
        'définitions'].to_dict()
    df['définitions'] = df.apply(
        lambda row: masculine_defs.get(row['lemme'], row['définitions'])
        if row['genre'] == 'f' else row['définitions'],
        axis=1
    )
    return df


def normalize_string(s: str) -> str:
    """
    Normalize a string by decomposing accented characters.
    (used for further sorting taking accented characters into account)

    Args:
    - s: The input string.

    Returns:
    The normalized string.
    """
    return unicodedata.normalize('NFD', s)


def sort_and_export_df(df: pd.DataFrame, sort_column: str, output_file: str) -> None:
    """
    Sort a DataFrame by a specified column (handling accented characters) and export it as a CSV file.
    A temporary 'normalized' column is used to handle accent comparison.

    Args:
    - df: The DataFrame to sort and export.
    - sort_column: The column name to sort by.
    - output_file: The full path for the output CSV file.
    """
    df['normalized'] = df[sort_column].apply(normalize_string)
    df.sort_values(by='normalized', inplace=True)
    df.drop(columns='normalized', inplace=True)
    df['display_date'] = None  # Add new column
    df.to_csv(output_file, index=False, quoting=1)
    print(f"Exported processed data to {output_file}")


def main() -> None:
    """
    Main function that:
      - Loads Lexique and Dico data (downloading files and creating folders if needed).
      - Filters the Lexique data and calculates a custom frequency index.
      - Merges the Lexique and Dico DataFrames.
      - Aggregates definitions.
      - Updates feminine definitions to align them with masculine ones.
      - Cleans and processes the definitions.
      - Sorts the final DataFrame and exports it as a CSV file.
    """
    lexique_df, dico_df = check_and_load_data(LEXIQUE_FILE, DICO_FILE)
    filtered_lexique_df = filter_lexique_and_calculate_custom_freq_index(
        lexique_df)
    merged_df = merge_dataframes(dico_df, filtered_lexique_df)
    merged_df = merged_df.drop_duplicates().drop(columns=['Mot'])

    # Aggregate definitions
    combined_df: pd.DataFrame = merged_df.groupby(
        ['mot', 'genre', 'lemme', 'phonétique'], dropna=False, as_index=False
    ).agg({
        'custom_freq_index': 'min',
        'définitions': lambda defs: str(sum([ast.literal_eval(d) for d in defs], []))
    })

    gender_aligned_df: pd.DataFrame = update_feminine_definitions(combined_df)
    processed_df: pd.DataFrame = clean_and_process_definitions(
        gender_aligned_df)
    sort_and_export_df(processed_df, 'mot', OUTPUT_FILE)


if __name__ == '__main__':
    main()
