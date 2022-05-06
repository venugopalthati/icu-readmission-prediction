# ICU Readmission Prediction

 This repo contains code for the raw data extraction, data preprocessing, and implementation of the LSTM and LSTM+CNN models for the paper "Design and implementation of a deep recurrent model for prediction of readmission in urgent care using electronic health records"

## Pre-requisites to use code from this repo

- Install PostgreSQL in the local machine <https://www.postgresql.org/download/>
- Install DBEaver community edition <https://dbeaver.io/download/>
- Install Python <https://www.python.org/downloads/>
- Install pip <https://pip.pypa.io/en/stable/installation/>
- Install python modules [pandas](https://pandas.pydata.org/docs/getting_started/install.html#installing-from-pypi), [numpy](https://numpy.org/install/), [pytorch](https://pytorch.org/get-started/locally/#start-locally), [imblearn](https://pypi.org/project/imblearn/), [scikit-learn](https://scikit-learn.org/stable/install.html)


## Paper

<https://ieeexplore.ieee.org/document/8791466>

## Dataset

Follow instructions in this link to get access to the MIMIC-III dataset used in the paper <https://eicu-crd.mit.edu/gettingstarted/access/>

## Importing Dataset

Follow instructions from this repo to import the MIMIC-III dataset into PostgreSQL database. <https://github.com/MIT-LCP/mimic-code/tree/main/mimic-iii/buildmimic/postgres>

## Extract raw data required for the research

Execute queries from [extract_data.sql](/extract_data.sql)  to extract the raw data in CSV files. This data will be processed in the next step. 

## Data pre-processing

Execute steps from the jupyter notebook [Process_ICU_Stays.ipynb](/Process_ICU_Stays.ipynb) to pre-process the data and save the output of pre-processing as numpy arrays.

## Model

### LSTM with Chart events

Execute steps from the jupyter notebook [Project_Model_LSTM_CHARTEVENTS.ipynb](/Project_Model_LSTM_CHARTEVENTS.ipynb) to train and test the LSTM model with Chart events dataset.

### LSTM  with Chart events + ICD9 + Patient Demographics

Execute steps from the jupyter notebook [Project_Model_LSTM_CHARTEVENTS_ICD9_DEMOGRAPHIC.ipynb](/Project_Model_LSTM_CHARTEVENTS_ICD9_DEMOGRAPHIC.ipynb) to train and test the LSTM model with Chart events dataset, ICD9 groups and patient demographics.

### LSTM+CNN (3 layers)  with Chart events + ICD9 + Patient Demographics

Execute steps from the jupyter notebook [Project_Model_LSTM_CNN_CHARTEVENTS_ICD9_DEMOGRAPHIC.ipynb](/Project_Model_LSTM_CNN_CHARTEVENTS_ICD9_DEMOGRAPHIC.ipynb) to train and test the LSTM+CNN model with Chart events dataset, ICD9 groups and patient demographics.

### LSTM+CNN (6 layers)  with Chart events + ICD9 + Patient Demographics

Execute steps from the jupyter notebook [Project_Model_LSTM_CNN_6_CHARTEVENTS_ICD9_DEMOGRAPHIC.ipynb](/Project_Model_LSTM_CNN_6_CHARTEVENTS_ICD9_DEMOGRAPHIC.ipynb) to train and test the LSTM+CNN model with Chart events dataset, ICD9 groups and patient demographics.

### Results


<img width="700" alt="Results" src="https://user-images.githubusercontent.com/5384400/167064222-d7611143-090c-4408-b87d-3890f3d97462.png">
