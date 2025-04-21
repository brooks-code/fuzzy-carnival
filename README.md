# dailyword

**One word a day keeps brain rot away.**

![Banner Image](<img/Dictionnaire mini-débutants 1990.jpg> "An image depicting the syren entry and its illustration in a children's dictionary (french).")
*Larousse's mini débutants dictionary (1990).*

**dailyword** is a (very) simple bash computer program that unveils a new random word along with its definition(s) helping you review french words progressively, once a day, one at a time straight from your terminal.
Furthermore, the displayed words are not common words. They have been carefully extracted by cross-referencing two datasets. You'll find more informations about the dataset building in the [processing](#data-processing) part and in the [acknowledgments](#acknowledgments).

![Demo Image](<img/dailyword.png> "Demonstration of the dailyword package running in the terminal.")
*Pardon my french ;)*

## Genesis

> The idea occurred to me when I came accross a Guillemette Faure [article](https://www.lemonde.fr/m-le-mag/article/2025/04/12/braillonne-n-m-celui-qui-parle-tres-fort-de-son-impossibilite-de-parler_6594625_4500055.html). Why not having something like this? But not in the shape of another [heavyweight app](https://en.wiktionary.org/wiki/use_a_sledgehammer_to_crack_a_nut). There are already too much of these, and most just keep increasing our mental workload until we stop using them after a short time. Nah, I wanted to take over an unexplored space, in a **simple and minimalist** fashion that could spark my curiosity without being overly intrusive nor distracting. What's better space for that purpose than a terminal? So, after a weekend of tinkering, here it is! The first prototype. There is a broad scope of possibilities in there: I really *invite you* to take over the concept and make it your own daily greeting space somehow. That could be a mental challenge, an excerpt from your favourite book.. Whatever, as long as it's reflects a genuine part of your self and makes your day start with a simple and yet mesmerizing smile.

## Table of Content

<details>
<summary>Contents - click to expand</summary>

- [dailyword](#dailyword)
  - [Genesis](#genesis)
  - [Table of Content](#table-of-content)
  - [Requirements](#requirements)
    - [Installation requirements](#installation-requirements)
    - [Usage requirements](#usage-requirements)
    - [Dataset building](#dataset-building)
  - [Installation](#installation)
    - [On Debian/Ubuntu based distros](#on-debianubuntu-based-distros)
    - [Removal](#removal)
      - [Manual installation (not recommanded)](#manual-installation-not-recommanded)
  - [Usage command](#usage-command)
  - [Package structure](#package-structure)
  - [Configuration](#configuration)
  - [Data processing](#data-processing)
  - [Limitations](#limitations)
  - [Improvements](#improvements)
  - [Troubleshooting](#troubleshooting)
  - [Further learning](#further-learning)
  - [Contributing](#contributing)
  - [Legal](#legal)
    - [License](#license)
    - [Disclaimer](#disclaimer)
  - [Acknowledgments](#acknowledgments)

</details>

## Requirements

### Installation requirements

- The [**dailyword.deb**](https://github.com/brooks-code/fuzzy-carnival/releases/download/v1.0.0/dailyword.deb) file and dpkg (built-in Debian/Ubuntu based systems).

### Usage requirements

- Only *Bash* (or a compatible shell), that's it, really.
  - Standard Unix utilities: date, awk (preferably GNU awk for FPAT), sed, printf, mv, grep and alias (built-in shell).

> [!NOTE]
> **In short:** you should not need to install anything more than the *dailyword* program. In standard Unix systems, required utilities are built-in by default.

### Dataset building

Only if you want to experiment with the [data processing](#data-processing) and build the definitions dataset from scratch. You'll need:

- Python (3.7 or newer)
- pandas (1.3.5 or newer)
- requests (2.31.0 or newer)

Open the terminal and in the processing folder, run:

```bash
pip install -r requirements.txt   
```

You can then run the processing script from you favourite IDE or manually with:

```bash
python3 processing.py  
```

> [!NOTE]
> If you installed the .deb package, the computed dataset is already located in the `opt/dailyword/data` folder of your system. You can also find all the archived datasets in the `src/data/datasets_backup` folder of this repository.

## Installation

### On Debian/Ubuntu based distros

Run the installation script:

   ```bash
 curl -sL https://raw.githubusercontent.com/brooks-code/fuzzy-carnival/main/install_dailyword.sh | bash
   ```

This command automates the download and installation process of the **dailyword.deb** package.

### Removal

You can then remove the software like this:

   ```bash
   sudo dpkg -r dailyword
   ```

This will remove all the installed files and restore the .bashrc file to its initial state.

#### Manual installation (not recommanded)

<details>
<summary>Click to expand</summary>

If for any reason, you don't want to use the .deb package. On GNU/POSIX compatible systems, you can still set it up manually:

1. Download (and unpack) or clone this repository:

    ```bash
    git clone https://github.com/brooks-code/fuzzy-carnival.git
    cd fuzzy-carnival-main # if you're not in the created directory already.
    ```

2. From your local folder, ensure `dailyword.sh` is executable, and copy the relevant contents of the `src` folder to your system's `opt` folder:

    ```bash
    chmod +x src/dailyword.sh && sudo mkdir -p /opt/dailyword && sudo cp src/dailyword.sh /opt/dailyword/ && sudo cp -r src/data /opt/dailyword/
    ```

    Change permissions of the dictionary file's data folder:

    ```bash
    sudo chown -R $(whoami):$(whoami) /opt/dailyword/data/
    ```

3. *Optional*. You can already test **dailyword** with this command:

    ```bash
    /opt/dailyword/dailyword.sh
    ```

4. Copy the `daily_bashrc.sh` file to your distro's `etc/profile.d` folder:

    ```bash
    sudo cp src/daily_bashrc.sh /etc/profile.d/
    ```

    *NB:* If you copied the source files in some other folder than the default `/opt/dailyword/` mentioned above, you will have to update the content of the `daily_bash.rc` file accordingly.

5. Update your distros `.bashrc` file equivalent by sourcing `daily_bashrc.sh`:

    ```bash
    echo "source /etc/profile.d/daily_bashrc.sh" >> ~/.bashrc
    ```

    From now on, your terminal will display a new word once a day at startup.

6. Remove unneeded files.

    ```bash
    cd .. && rm -rf fuzzy-carnival-main
    ```

To uninstall dailyword manually, you can undo the steps from 5 to 1 mentioned above with this command.

```bash
sed -i '/source \/etc\/profile.d\/daily_bashrc.sh/d' ~/.bashrc && sudo rm -rf /etc/profile.d/daily_bashrc.sh && sudo rm -rf /opt/dailyword && rm -f ~/.dailyword && source ~/.bashrc
```

This command will:

1. Remove the line sourcing `daily_bashrc.sh` from `.bashrc`.
2. Delete the `daily_bashrc.sh` file from `/etc/profile.d`.
3. Remove the application files from `/opt/dailyword` and delete the folder.
4. Delete the `.dailyword` marker file from the home folder if it exists.
5. Reload the `.bashrc` file to apply the changes.

</details>

## Usage command

The script displays a new word, once, every new day. You have nothing more to do! If you forgot your daily surprise, you can invoke it back during the current day with:

   ```bash
   oogf
   ```

Why oogf? Well that's a long story, but for the mnemonic association, just remember that the acronym stands for: *Oh oui, grand.e fou.e!* (inclusive form for: *oh yeah, crazy girl!* or *oh yeah, crazy boy!*). That might help you remember the magic command.

The CSV file is updated after every display change, so you can still find a word you'd like to recall by it's display date (range).

## Package structure

```bash
dailyword/  
├── DEBIAN  
│   ├── control  
│   ├── postinst  
│   └── prerm  
├── etc  
│   └── profile.d  
│       └── daily_bashrc.sh         # source file for .bashrc
└── opt    
    └── dailyword  
        ├── dailyword.sh            # main bash script
        └── data  
            └── daily_words.csv     # dataset
```

## Configuration

The script utilizes the following configuration variables:

```bash
CSV_FILE: # Path to the CSV file containing the words and definitions.
# (default: (app_dir)/data/daily_words.csv)

ASCII_ART: # Decorative text art displayed at the top.
ASCII_COLOR: # Color used for displaying ASCII art header (default: copper).

# Gradient configuration variables:
GRADIENT_START: # The starting RGB values for the gradient (default: Teal - [0, 128, 128])
GRADIENT_END: # The ending RGB values for the gradient (default: Dark Orange - [255, 140, 0])
SCALE: # Used for calculating the gradient steps.
```

The colors have been selected to fit both dark and light terminal modes. You can adjust these variables directly in the script if you need some changes to better reflect your visual preferences and environment.

## Data processing

The main objective is to provide new words to be discovered with the challenge of avoiding too common words. To ensure that, the processing leverages two datasets: Lexique and Dico.
The processing script keeps only pertinent columns in Lexique and computes a custom frequency index (a weighted average) that synthetizes frequencies based on different measures. After reading [this](http://openlexicon.fr/datasets-info/Lexique382/Manuel_Lexique3.html#__RefHeading___Toc152122352) (french), the choice has been made to emphasize the weights of the book-related frequency indexes since, vocabulary found in literature tends to be more nuanced and sophisticated than the one used in movies.

The process is followed by augmenting the data with matching definitions entries from the Dico dataset. The cleaning process removes duplicates and words considered as too common (i.e. too frequent) based on the custom frequency threshold. Also, definitions with keywords who potentially indicate a definition with less informational value will be filtered out. The script also corrects a bias occuring for some feminine definitions to ensure equivalent levels of description for both genders.

Finally, the sorted results, with their handled accented characters, are exported to a CSV file, thus providing an informative list ready to be processed by the dailyword program.

| Column Name        | Description                                                                 | Type               |
|--------------------|-----------------------------------------------------------------------------|--------------------|
| **mot**            | The word or term being defined.                                            | String             |
| **genre**          | Gender: (m)asculine, (f)eminine or missing ("").                          | String (1 char)    |
| **lemme**          | The base form or lemma of the word, often used in linguistic analysis.     | String             |
| **phonétique**     | The phonetic representation of the word, indicating how it is pronounced. More information [here](http://openlexicon.fr/datasets-info/Lexique382/Manuel_Lexique3.html#__RefHeading___Toc152122370) (french).  | String             |
| **custom_freq_index**| A numerical score that represents a weighted average of several indexes related to frequencies. More weights have been added on the books related frequencies, read why [here](http://openlexicon.fr/datasets-info/Lexique382/Manuel_Lexique3.html#__RefHeading___Toc152122353) (french). Frequencies are occurrences per million words (pmw). | Float    |
| **définitions**    | The definitions or meanings of the word. Multiple definitions are separated by a pipe symbol. | String             |
| **display_date**   | The date on which the word and its information have been displayed.        | Date (YYYY-MM-DD)  |

Example:

```csv
"mot","genre","lemme","phonétique","custom_freq_index","définitions","display_date"
"abaca","m","abaca","abaka","0.002","Bananier des Philippines de la famille des musacées, dont les feuilles fournissent le chanvre de Manille, une matière textile. | Fibre textile tirée du bananier du même nom, appelée aussi chanvre de Manille ou tagal.",""
```

As you see can see above, in case of polysemy, definitions are separated by a ` | ` (pipe) symbol.

## Limitations

- A slight lag occurs while the dataset is being processed during the awk pass.
- The script depends on GNU awk, which supports the FPAT variable. Compatibility may vary on different systems.

## Improvements

- [ ] Use more advanced NLP techniques during data processing to ensure a better semantic discoverability.
- [ ] Keep optimizing the main script for better performance.

## Troubleshooting

- If you get the `Error: CSV file not found` message, verify that the CSV file path in the `dailyword.sh` script points to the correct location and that the file is accessible.
- If no definition is displayed and the output returns `No more definitions to display`, ensure that there are still definitions left in the CSV with an empty value in the `display_date` column.
- If the definitions are not appearing, each day, the first time you launch your terminal and the `oogf` command is throwing back an error, please check if your `.bashrc` file is correctly sourced.
- Check that your terminal supports 24-bit (true color) for the gradient display to be displayed correctly.
- For compatibility issues with awk, ensure your version supports FPAT or consider installing GNU awk.

## Further learning

- Review Bash scripting [fundamentals](https://earthly.dev/blog/linux-text-processing-commands/) for text processing.
- ANSI escape codes [cheatsheet](https://gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25b) (used for colorful terminal outputs).
- Explore how CSV files can be managed and updated via Unix command-line utilities. [Link 1](https://earthly.dev/blog/awk-examples/), [Link 2](https://www.gnu.org/software/gawk/manual/html_node/index.html#SEC_Contents).

## Contributing

Feel free to open issues or discuss any improvements.
Contributions are welcome! Each contribution and feedback helps improve this project - it's always an honour :)

- Fork the repository.
- Create a branch for your feature or bug fix.
- Submit a pull request with your changes.

## Legal

### License

The source code is provided under the [Unlicense](https://unlicense.org/) license. See the [LICENSE](/LICENSE) file for details.

### Disclaimer

This project is not affiliated with or endorsed by any third party. It is provided as is for educational and practical uses. Use it at your own risk (and always back up your data).

## Acknowledgments

This software makes use of various [open source libraries and Unix utilities](#requirements). Special **thanks** to the developers and the community for providing these valuable tools.

**Datasets:**

- Lexique 3 ([version 3.83](http://www.lexique.org/databases/Lexique383/Lexique383.tsv)) provided valuable insights about french words frequencies. More information [here](http://www.lexique.org/databases/Lexique383/Manuel_Lexique.3.pdf).

```markdown
@article{New2001,
  author = {New, B. and Pallier, C. and Ferrand, L. and Matos, R.},
  title = {Une base de données lexicales du français contemporain sur internet: LEXIQUE},
  journal = {L'Année Psychologique},
  volume = {101},
  pages = {447-462},
  year = {2001},
  url = {http://www.lexique.org}
}

@article{New2004,
  author = {New, B. and Pallier, C. and Brysbaert, M. and Ferrand, L.},
  title = {Lexique 2 : A New French Lexical Database},
  journal = {Behavior Research Methods, Instruments, & Computers},
  volume = {36},
  number = {3},
  pages = {516-524},
  year = {2004}
}
```

- [Kartmaan's](https://github.com/Kartmaan/french-language-tools) french wiktionary *(wiktionnaire)* [CSV dump](https://github.com/Kartmaan/french-language-tools/blob/master/files/dico.csv), for providing definitions. Also available on [Kaggle](https://www.kaggle.com/datasets/kartmaan/dictionnaire-francais).

**Misc:**
  
- Ascii header computed with [pyfiglet](https://pypi.org/project/pyfiglet/) using the [slscript](http://www.figlet.org/examples.html) font.
