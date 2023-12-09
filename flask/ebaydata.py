from flask import Flask,request, render_template
import requests

import os
from ebay_oauth_token import OAuthToken



api_key = "WilliamL-hw2-PRD-aaf878574-a94ce998"
# findItemsAdvanced
def get_data(keyword,minPrice,maxPrice,conditions,seller_return_accepted,free_shipping,expedited_shipping,sort_order='BestMatch'):
    ebay_api_url = 'https://svcs.ebay.com/services/search/FindingService/v1'

    ebay_api_params = {
        'OPERATION-NAME': 'findItemsAdvanced',
        'SERVICE-VERSION': '1.0.0',
        'SECURITY-APPNAME':api_key, 
        'RESPONSE-DATA-FORMAT': 'JSON',
        'REST-PAYLOAD': 'true',
        'keywords': keyword,
        'paginationInput.entriesPerPage': '100',  
        
    }

    itemCounter = 0 # itemFilter counter

    if maxPrice:
        ebay_api_params[f"itemFilter({itemCounter}).name"]="MaxPrice"
        ebay_api_params[f"itemFilter({itemCounter}).value"] = maxPrice
        ebay_api_params[f"itemFilter({itemCounter}).paramName"] = "Currency"
        ebay_api_params[f"itemFilter({itemCounter}).paramValue"] = "USD"
        itemCounter += 1

    if minPrice:
        ebay_api_params[f"itemFilter({itemCounter}).name"]="MinPrice"
        ebay_api_params[f"itemFilter({itemCounter}).value"] = minPrice
        ebay_api_params[f"itemFilter({itemCounter}).paramName"] = "Currency"
        ebay_api_params[f"itemFilter({itemCounter}).paramValue"] = "USD"
        itemCounter += 1

    
    if conditions:
        ebay_api_params[f'itemFilter({itemCounter}).name'] = 'Condition'
        for i, condition in enumerate(conditions):
            ebay_api_params[f'itemFilter({itemCounter}).value({i})'] = condition
        itemCounter += 1

    if seller_return_accepted:
        ebay_api_params[f"itemFilter({itemCounter}).name"] = "ReturnsAcceptedOnly"
        ebay_api_params[f"itemFilter({itemCounter}).value"] = "true" if seller_return_accepted else "false"
        itemCounter += 1

        

    if free_shipping:
        ebay_api_params[f"itemFilter({itemCounter}).name"] = "FreeShippingOnly"
        ebay_api_params[f"itemFilter({itemCounter}).value"] = "true"
        itemCounter += 1

    if expedited_shipping:
        ebay_api_params[f"itemFilter({itemCounter}).name"] = "ExpeditedShippingType"
        ebay_api_params[f"itemFilter({itemCounter}).value"] = "Expedited"
        itemCounter += 1

    
    
    if sort_order is not None:
        ebay_api_params["sortOrder"] = sort_order

    # make the dictionary into a string url
    query_string = '&'.join([f'{key}={value}' for key, value in ebay_api_params.items()])
    ebay_api_url= ebay_api_url+'?'+query_string

    # print('the url you generate:',ebay_api_url)
    response = requests.get(ebay_api_url).json()
    
    return response


# getSingleItem
client_id =api_key
client_secret = "PRD-af878574c693-c7c9-4e95-b263-9852"
oauth_utility = OAuthToken(client_id, client_secret)
application_token = oauth_utility.getApplicationToken()
def get_single_data(item_id):
    headers = {
    "X-EBAY-API-IAF-TOKEN": oauth_utility.getApplicationToken(),
    }
    
    response_single = requests.get(f'https://open.api.ebay.com/shopping?callname=GetSingleItem&responseencoding=JSON&appid=WilliamL-hw2-PRD-aaf878574-a94ce998&siteid=0&version=967&ItemID={item_id}&IncludeSelector=Description,Details,ItemSpecifics', headers=headers)
    
    return response_single.json()
# print(get_single_data('175901174512'))
