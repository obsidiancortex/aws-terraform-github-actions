import time
import pandas as pd

from selenium import webdriver 
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager

url = 'https://www.letour.fr/en/rankings' 

driver = webdriver.Chrome(service=ChromeService(
    ChromeDriverManager().install()))
driver.maximize_window()

driver.get(url)

