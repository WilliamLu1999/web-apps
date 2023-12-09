from flask import Flask, render_template, request, jsonify
from ebaydata import get_data, get_single_data
application = Flask(__name__)

@application.route("/",methods=['GET']) # because everything will be on the same page
def index():
    return render_template('index.html')

@application.route("/search",methods=["GET"])
def search():
   
    keywords = request.args.get('Keywords')
    min_price = request.args.get('min-price')
    max_price = request.args.get('max-price')
    condition = request.args.getlist('choice') 
    seller = request.args.getlist('seller')  
    freeshipping = request.args.get('freeshipping')
    expeditedshipping = request.args.get('expeditedshipping')
    sortby = request.args.get('sortby')


    

    data = get_data(keywords,min_price,max_price, condition, seller, freeshipping,expeditedshipping, sortby) 
    return jsonify(data)
    #print(keywords)
    #print(data)
    #print(keywords, min_price, max_price, condition, seller, shipping, sortby)
    
    #return render_template('index.html',search_results=data)
    #return render_template('index.html')
# jsonify(data)
    # Render the search_results.html template with the data

@application.route("/singles/<string:item_id>", methods=["GET"])
def getinfoSingle(item_id):
    #item_id = request.args.get('itemId')
    print("Received request for item ID:", item_id) 
    data = get_single_data(item_id)

    return jsonify(data)
    
    
if __name__=='__main__':
    application.run(debug=True)