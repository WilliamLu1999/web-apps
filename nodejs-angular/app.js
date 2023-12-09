const express = require('express');
const path = require('path');
const cors = require('cors');
const { get_data, get_single_data} = require('./ebaydata.js'); 
const app = express();
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const axios = require('axios')
const corsOptions = {
    origin: process.env.FRONTEND_URL ||'http://localhost:4200', 
  };
// const password = 'abcdefg';
// const escapedPassword = encodeURIComponent(password);
app.use(bodyParser.json());
app.use(cors(corsOptions));



app.use(express.static(path.join(__dirname, 'frontend/dist/frontend')));



const port = process.env.PORT || 3000;

const connectionString = `mongodb+srv://anotherme:abcdefg@cluster0.jdddo1r.mongodb.net/?retryWrites=true&w=majority`;

mongoose.connect(connectionString, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log('MongoDB Connected'))
  .catch((error) => {
    console.error('MongoDB Connection Error:', error);
  });
// to connect MongoDB
const ItemSchema = new mongoose.Schema({
  itemId: String,
  galleryURL: String,
  title: String,
  currentPrice: Number,
  shippingServiceCost: Number,
  postalCode: String
  
});

const Item = mongoose.model('Item', ItemSchema);



const api_key = 'WilliamL-hw2-PRD-aaf878574-a94ce998';

// eBay API URL
const ebayApiUrl = 'https://svcs.ebay.com/services/search/FindingService/v1';



// test test

//app.get('/', (req, res) => {
  // Define the response for the root URL
  //res.send('Welcome to the eBay search application');
//});

app.get('/api/data', (req, res) => {
    const jsonData = { message: "balabala from the backend" };
    res.json(jsonData);
  });
  
// query backend data  

app.get("/search",async (req,res)=>{
  try {
    

    const keywords = req.query.keywords || '';
    const category = req.query.category || '';
    const conditions = [];
    
    if (req.query.newCondition === 'true') {
      conditions.push('New');
    }
    if (req.query.usedCondition === 'true') {
      conditions.push('Used');
    }
    if (req.query.unspecifiedCondition === 'true') {
      conditions.push('Unspecified');
    }
    
    const shippingOptions = [];

    if (req.query.freeShipping === 'true') {
      shippingOptions.push('Free Shipping');
    }
    if (req.query.localPickup === 'true') {
      shippingOptions.push('Local Pickup');
    }
    // const shippingOptions=[freeShipping,localPickup]
    const distanceMiles = parseInt(req.query.distanceMiles) || 0;
    let postal = req.query.postal || '';
   

    // Call the get_data function with the provided parameters
    const data = await get_data(keywords,category,conditions,shippingOptions,distanceMiles,postal)
    
    console.log(data)
    res.json(data);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'An error occurred' });
  }
});
get_data('iphone', 'Computers/Tablets & Networking', ['New','Used'], ['Free Shipping', 'Local Pickup'], 10, '90007');
// app.get('/getItemsFromCart', async (req, res) => {
//   try {
//     const items = await Item.find();
//     res.status(200).json(items);
//   } catch (err) {
//     console.error(err);

//     res.status(500).send(err);
//   }
// });

app.post('/addItemToCart', async (req, res) => {
  console.log('Received a POST request to /addItemToCart');
  
  // Extract values from arrays if they are arrays
  let itemId = Array.isArray(req.body.itemId) ? req.body.itemId[0] : req.body.itemId;
  let galleryURL = Array.isArray(req.body.galleryURL) ? req.body.galleryURL[0] : req.body.galleryURL;
  let title = Array.isArray(req.body.title) ? req.body.title[0] : req.body.title;
  let postalCode = Array.isArray(req.body.postalCode) ? req.body.postalCode[0] : req.body.postalCode;
  let currentPrice = req.body.currentPrice;
  let shippingServiceCost = req.body.shippingServiceCost;

  // Create a new item using the values
  let newItem = new Item({
      itemId: itemId,
      galleryURL: galleryURL,
      title: title,
      currentPrice: currentPrice,
      shippingServiceCost: shippingServiceCost,
      postalCode: postalCode
  });

  // Try to save the item and catch any errors that occur
  try {
      let savedItem = await newItem.save();
      console.log(savedItem)
      res.status(200).json(savedItem);
  } catch (err) {
      res.status(500).send(err);
  }
});


app.delete('/removeItemFromCart/:itemId', async (req, res) => {
  console.log('Received a DELETE request to /removeItemFromCart');
  

  const itemId = req.params.itemId;
  console.log('Trying to delete item with ID:', itemId);
  try {
      let result = await Item.deleteOne({ itemId: itemId });
      if (result.deletedCount === 1) {
          res.status(200).json({ success: true, message: 'Item removed successfully 2' });
      } else {
          res.status(404).json({ success: false, message: 'Item not found in the database' });
      }
  } catch (err) {
      res.status(500).json({ success: false, message: 'Server error', error: err.message });
  }
});




app.get('/wishData', async (req, res) => {
  try {
      const wishitems = await Item.find();  // Fetch all documents from the 'Wish' collection
      res.json(wishitems);
  } catch (err) {
      console.error(err);
      res.status(500).send('Server Error');
  }
});

app.get('/item/:id', async (req, res) => {
  try {
      const itemId = req.params.id;
      const itemData = await get_single_data(itemId);
      // Render item details or send the data
      res.json(itemData);
  } catch (error) {
      console.error('Error:', error);
      res.status(500).send('Server error');
  }
});


// for phots tab



app.get('/searchPhotos', async (req, res) => {
  console.log("Search photos start!")
  try {
    const productTitle = req.query.itemTitle;
    const params = {
      q: productTitle,
      cx: '110ff0d779ec248d2',
      imgSize: 'huge',
      num: 8,
      searchType: 'image',
      key: 'AIzaSyDtGlm3fnmE2YkIcI2EcXXtygpoXkTpxtE'
    };
    console.log("loading this product title: ",productTitle)
    // Build the full URL manually
    const queryParams = new URLSearchParams(params).toString();
    const fullUrl = `https://www.googleapis.com/customsearch/v1?${queryParams}`;

    // Log the full URL
    console.log('Requesting URL:', fullUrl);

    // Now make the request with axios
    const response = await axios.get(fullUrl);
    console.log(response)
    const images = response.data.items.map(item => item.link);
    res.json({ images });
    
    // Send the response back
    console.log("Success photos!")
  } catch (error) {
    console.error('Error fetching images:', error);
    res.status(500).send(error.message);
  }
});


// find similar items

app.get('/similarItems/:itemId', async (req, res) => {
  console.log("I got into finding similar products in the backend")
  const itemId = req.params.itemId;
  console.log("the itemID of the item I want to find similarities with")
  const url = `https://svcs.ebay.com/MerchandisingService?OPERATION-NAME=getSimilarItems&SERVICE-NAME=MerchandisingService&SERVICE-VERSION=1.1.0&CONSUMER-ID=WilliamL-hw2-PRD-aaf878574-a94ce998&RESPONSE-DATA-FORMAT=JSON&REST-PAYLOAD&itemId=${itemId}&maxResults=20`
  try {
    console.log(url)
    const response = await axios.get(url);
    console.log(response)
    res.json(response.data);
  } catch (error) {
    console.error('Error fetching similar items:', error);
    res.status(500).send(error.message);
  }
});



app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'frontend/dist/frontend/index.html'));
});


app.listen(port, () => {
    console.log(`Express server is running on port ${port}`);
  });




// module.exports = app;