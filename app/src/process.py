import json
from db import db_helper
from selenium.webdriver.common.by import By
from selenium import webdriver

def lambda_handler(event=None, context=None):
    request = get_request(event=event)
    if request is None:
        return {
            "statusCode": 400,
            "body": {
                "message": "Cannot parse url"
            }
        }
    
    dbHelper = db_helper.DBHelper()
    try:
        dbHelper.update_order_status(request=request, status='In Progress')

        url = request['url']

        driver = get_driver()
        driver.get(url)
        search_results = driver.find_elements(By.XPATH, "//div[@data-header-feature]")
        dbHelper.update_order_status(request=request, status='Complete')
            
    except Exception as e:
        print(e)
        dbHelper.update_order_status(request=request, status='Failed')
        return {
            "statusCode": 500,
            "body": {
                "message": f"Error processing request: {e}"
            }
        }

        
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "records found": len(search_results),
            }
        ),
    }

def get_request(event) -> str:
    if "Records" in event:
        body = event['Records'][0]['body']
        event = json.loads(body)
    return event

def get_driver():
    chrome_options = webdriver.ChromeOptions()
    chrome_options.binary_location = "/opt/chrome/chrome"
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--disable-dev-tools")
    chrome_options.add_argument("--no-zygote")
    chrome_options.add_argument("--single-process")
    chrome_options.add_argument("window-size=2560x1440")
    chrome_options.add_argument("--remote-debugging-port=9222")
    input_driver = webdriver.Chrome("/opt/chromedriver", options=chrome_options)
    return input_driver