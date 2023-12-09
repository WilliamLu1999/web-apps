const axios = require('axios');
const client_id = 'WilliamL-hw2-PRD-aaf878574-a94ce998';
const client_secret = 'PRD-af878574c693-c7c9-4e95-b263-9852';
const OAuthToken = require('./ebay_oauth_token.js');

const oauth_utility = new OAuthToken(client_id, client_secret);
const api_key = 'WilliamL-hw2-PRD-aaf878574-a94ce998';

async function get_data(keyword, category, condition, shippingOptions, distanceMiles, postal) {
    const ebayApiUrl = 'https://svcs.ebay.com/services/search/FindingService/v1';
    const categoryMappings = {
        'Art': 550,
        'Baby': 2984,
        'Books': 267,
        'Clothing, Shoes, Accessories': 11450,
        'Computers/Tablets & Networking': 58058,
        'Health & Beauty': 26395,
        'Music': 11233,
        'Video Games & Consoles': 1249
    };
    const ebayApiParams = {
        'OPERATION-NAME': 'findItemsAdvanced',
        'SERVICE-VERSION': '1.0.0',
        'SECURITY-APPNAME': api_key,
        'RESPONSE-DATA-FORMAT': 'JSON',
        'REST-PAYLOAD': 'true',
        'keywords': keyword,
        'paginationInput.entriesPerPage': '50',
    };

    let itemFilterIndex = 0;

    if (distanceMiles) {
        ebayApiParams[`itemFilter(${itemFilterIndex}).name`] = 'MaxDistance';
        ebayApiParams[`itemFilter(${itemFilterIndex}).value`] = distanceMiles;
        itemFilterIndex++;
    }
    let conditionIndex = 0;
    if (condition && condition.length > 0) {
        console.log('i go inside')
        const conditions = Array.isArray(condition) ? condition : [condition]; // Ensure it's an array
        ebayApiParams[`itemFilter(${itemFilterIndex}).name`] = 'Condition';
    
        conditions.forEach((value, index) => {
            ebayApiParams[`itemFilter(${itemFilterIndex}).value(${index})`] = value;
        });
    
        itemFilterIndex++;
    }
    

    if (shippingOptions && shippingOptions.length > 0) {
        if (shippingOptions.includes('Local Pickup')) {
            ebayApiParams[`itemFilter(${itemFilterIndex}).name`] = 'LocalPickupOnly';
            ebayApiParams[`itemFilter(${itemFilterIndex}).value`] = 'true';
            itemFilterIndex++;
        }

        if (shippingOptions.includes('Free Shipping')) {
            ebayApiParams[`itemFilter(${itemFilterIndex}).name`] = 'FreeShippingOnly';
            ebayApiParams[`itemFilter(${itemFilterIndex}).value`] = 'true';
            itemFilterIndex++;
        }
    }

    if (category) {
        
        for (const cat in categoryMappings) {
            if (cat.toLowerCase().includes(category.toLowerCase())) {
                ebayApiParams['categoryId'] = categoryMappings[cat];
                break;
            }
        }
    }

    if (postal) {
        ebayApiParams['buyerPostalCode'] = postal;
    }

    const query_params = Object.keys(ebayApiParams)
        .map(key => `${key}=${encodeURIComponent(ebayApiParams[key])}`)
        .join('&');

    const ebayApiUrlWithParams = `${ebayApiUrl}?${query_params}&outputSelector(0)=SellerInfo&outputSelector(1)=StoreInfo`;// need to add this to match the instruction

    console.log('Constructed URL:', ebayApiUrlWithParams);

    try {
        // Send a GET request to the constructed URL
        const response = await axios.get(ebayApiUrlWithParams);
        console.log('eBay API Response:', response.data);
        return response.data;
    } catch (error) {
        console.error(error);
        throw error;
    }
}

// Example usage:
// get_data('iphone', 'Computers/Tablets & Networking', ['New','Used'], ['Free Shipping', 'Local Pickup'], 10, '90007');



  // Usage example


// async function getApplicationToken() {
//     try {
//         return await oauth_utility.getApplicationToken();
//     } catch (error) {
//         console.error('Error obtaining application token:', error);
//         throw error;
//     }
// }

async function get_single_data(item_id) {
    const headers = {
        "X-EBAY-API-IAF-TOKEN": await oauth_utility.getApplicationToken(),
    };

    const url = `https://open.api.ebay.com/shopping?callname=GetSingleItem&responseencoding=JSON&appid=WilliamL-hw2-PRD-aaf878574-a94ce998&siteid=0&version=967&ItemID=${item_id}&IncludeSelector=Description,Details,ItemSpecifics`;

    try {
        const response = await axios.get(url, { headers });
        return response.data;
    } catch (error) {
        console.error('Error obtaining single data:', error);
        throw error;
    }
}
// module.exports = get_single_data;
module.exports = {
    get_data,
    get_single_data
  };