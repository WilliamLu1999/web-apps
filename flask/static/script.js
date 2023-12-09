document.addEventListener("DOMContentLoaded", function () {
    function clearForm() {
        
        
        document.querySelector('input[type="text"]').value = "";
        
       
        document.getElementById("min-price").value = "";
        document.getElementById("max-price").value = "";

        
        var checkboxes = document.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(function (checkbox) {
            checkbox.checked = false;
        });

        
        document.querySelector('select[name="sortby"]').selectedIndex = 0;
    }

    function validatePriceRange(){
        //searchButton.style.backgroundColor = "#7EB563";
        setTimeout(function () {
            searchButton.style.backgroundColor = ""; // change it back to the original color
        }, 1000);
        const minPriceInput = document.getElementById('min-price');
        const maxPriceInput = document.getElementById('max-price');
        const minPrice = parseFloat(minPriceInput.value);
        const maxPrice = parseFloat(maxPriceInput.value);
        
        if (minPrice >maxPrice){
            alert("Oops! Lower price limit cannot be greater than upper price limit! Please try again.")
            minPriceInput = ""
            maxPriceInput = ""
        }
        
        if (minPrice < 0 || maxPrice<0){
            alert("Price Range values cannot be negative! Please try a value greater than or equal to 0.0")
            minPriceInput = ""
            maxPriceInput = ""
        }
    }
    
    $(document).ready(function () {
        var showMore = false; // flag for show more and show less button
        var initialItemCount = 3;
        var total_items_num = 0;
        var itemIdList = [];
        function showSingleItemDetails() {
            $("#search-results").hide();
            
            $("#search-results-single").show();
            $("#go-back-button-container").show();
        }
        
        // Function to show search results and hide single item details
        function showSearchResults() {
            $("#search-results").show();
            $("#search-results-single").hide();
            $("#go-back-button-container").hide();
        }
        
        $("#myform").submit(function (event) {
            
            event.preventDefault();

            var formData = $("#myform").serialize();
            
            $.ajax({
                type: "GET",
                url: "/search?"+formData,
                //data: formData,
               
                success: function (response) {
                    // Update the search results div with the JSON data
                    // console.log("Search successful:", response);
                    // console.log(formData);
                    if (response && response.findItemsAdvancedResponse){
                        // console.log(response);
                        var resultsHtml="";
                        //resultsHtml += "<pre>" + JSON.stringify(response, null, 2) + "</pre>";

                        // var resultsHtml = "<pre>" + JSON.stringify(response, null, 2) + "</pre>";
                        // to print the returned json data back to the html page
                        var totalEntries = response.findItemsAdvancedResponse[0].paginationOutput[0].totalEntries[0];
                        //var keyword =  document.getElementById("Keywords").value;
                        //resultsHtml += "<h2>"+totalEntries+ " Results found for "+ "<em>"+keyword+"</em>"+"</h2>" +"<hr id='results_pop'>";
                        var items = response.findItemsAdvancedResponse[0].searchResult[0].item;
                        
                        if (totalEntries>0){
                            totalItems = items.length;
                            var keyword =  document.getElementById("Keywords").value;
                            resultsHtml += "<h2>"+totalEntries+ " Results found for "+ "<em>"+keyword+"</em>"+"</h2>";
                            resultsHtml += "<hr id='results_pop' style='margin-bottom: 20px; width: 600px;'>";
                            
                            for (var i=0;i<items.length;i++){
                                var item = items[i];
                                var title = item.title && item.title[0];
                                var category = item.primaryCategory && item.primaryCategory[0].categoryName[0];
                                var condition  = item.condition && item.condition[0].conditionDisplayName[0];
                                var price = item.sellingStatus && item.sellingStatus[0].convertedCurrentPrice[0].__value__;
                                //var shipping_cost = item.shippingInfo[0].shippingServiceCost[0].__value__
                                
                                var shipping_cost = item.shippingInfo && item.shippingInfo[0].shippingServiceCost
                                    ? item.shippingInfo[0].shippingServiceCost[0].__value__
                                    : '0.0';
                                //var total_price = parseFloat(price) + parseFloat(shipping_cost);
                                var item_url_redirect = item.viewItemURL[0];
                                var item_id = item.itemId[0];
                                itemIdList.push(item_id);
                                var default_image = './static/ebay_default.jpg'
                                var category_word = 'Category: '
                                if (title && category && condition && price){
                                    resultsHtml += "<div class='item-bucket '"+"data-itemid="+item_id+">";
                                    resultsHtml += "<div class='product-image'>";
                                    resultsHtml += "<img src ='" + item.galleryURL[0]+"'"+"onerror='this.src="+'"'+default_image+'"'+"'/>";
                                    resultsHtml += '</div>';
                                    resultsHtml += '<div class="item-details">';
                                    resultsHtml += '<p class="item-title" style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis;max-width: 380px;">'+ title + '</p>';
                                    
                                    resultsHtml += '<p class="item-category" style="display: flex; align-items: center;">'+'Category: ' + '<span style="font-style: italic;">' + category + '</span> <a href="' + item_url_redirect + '" target="_blank"><img id="small-icon-redirect" src="../static/redirect.png" alt="View Details"></a></p>';
                                    //resultsHtml += '<a href="' + item_url_redirect + '" target="_blank"><img class ="small-icon" src="../static/redirect.png" alt="View Details"></a>';
                                    
                                    // Add top-rated image if applicable
                                    if (item.topRatedListing[0] === 'true') {
                                        resultsHtml += '<p class="item-condition" style="display: flex; align-items: center;">'+"Condition: "+condition + '<img id ="small-icon-top" src="../static/topRatedImage.png" alt="Top Rated">'+'</p>';
                                        
                                        //resultsHtml += '<img class ="small-icon" src="../static/topRatedImage.png" alt="Top Rated">';
                                    }
                                    else{
                                        resultsHtml += '<p class="item-condition">'+"Condition: "+condition + '</p>';
                                    }
                                    if (shipping_cost!=='0.0'){
                                        resultsHtml += '<p class="total-price"><strong>'+"Price: $" + price +' ( + $'+shipping_cost+' for shipping)'+ '</strong></p>';
                                    }
                                    else{
                                        resultsHtml += '<p class="total-price"><strong>'+"Price: $" + price + '</strong></p>';
                                    }
                                    resultsHtml += '</div>';
                                    
                                    resultsHtml += '</div>';

                                    
                                    }
                                

                            }
                            //var visibleItems = items.slice(0, initialItemCount);
                            
                        }else {
                            // Handle the case when items.length is less than or equal to 0 (no results found)
                            resultsHtml += "<h2>No results found.</h2>";
                            
                        }
                        

                    }

                    if (resultsHtml ==="<h2>No results found.</h2>"){
                        $("#search-results").html(resultsHtml);
                    }

                    else{
                        $("#search-results").html(resultsHtml);
                        var showMoreButton = $('<button id="show-more-btn">Show More</button>');
                        $("#search-results").append(showMoreButton);

                        $(".item-bucket:gt(" + (initialItemCount - 1) + ")").hide();

                        $("#show-more-btn").click(function(){
                            if (!showMore){
                                
                                $(".item-bucket:hidden").slice(0, Math.min(7, 3+$(".item-bucket:hidden").length)).show(); // Show the next 7 hidden item buckets
                                $("#show-more-btn").text("Show Less");
                                var scrollTo = $(document).height() - $(window).height(); // Calculate scroll position
                                $("html, body").animate({
                                    scrollTop: scrollTo
                                }, "slow");
                                
                            }
                            else{
                                $(".item-bucket:gt(" + (initialItemCount - 1) + ")").hide();
                                $("#show-more-btn").text("Show More");
                                $("html, body").animate({
                                    scrollTop:0
                                }, "slow");
                            }
                            showMore = !showMore;
                            
                        });
                    }
                    
                    $(".item-bucket").click(function(event){
                        if (!$(event.target).is("#small-icon-redirect")){
                        var item_id =$(this).data("itemid");
                        $.ajax({
                            type:"GET",
                            url:"/singles/"+item_id,
                            success:function(singleItem){
                                var temp_container = $("<div>").addClass("header-button-container");
                                var header = $("<h1>").text("Item Details");
                                var goBackButton=$("<button>")
                                    .attr("id","go-back-button")
                                    .text("Back to search results")
                                    .click(function(){
                                        showSearchResults();
                                        $(this).remove();
                                        $('#search-results-single').empty()
                                    });

                                    temp_container.append(header,goBackButton);
                                    $("#go-back-button-container").html(temp_container);
            
                            displaySingleItem(singleItem);
                            
                            showSingleItemDetails();
                            },
            
                            error: function(){
                                alert("An error occured while getting the single item details.");
                            },
            
                        });}
            
                        
                    });

                    //console.log(itemIdList);

                },
                error: function () {
                    alert("An error occurred during the search.");
                },
                
            });


        });
        
        function displaySingleItem(singleItem){
            
            var title = singleItem.Item.Title;
            var photoUrl = singleItem.Item.PictureURL[0];
            var itemUrl = singleItem.Item.ViewItemURLForNaturalSearch;
            var price = singleItem.Item.ConvertedCurrentPrice.Value;
            var subTitle = singleItem.Item.Subtitle;
            var location = singleItem.Item.Location;
            var seller = singleItem.Item.Seller;
            var returnPolicy = singleItem.Item.ReturnPolicy;
            var itemSpecifics = singleItem.Item.ItemSpecifics.NameValueList;

           
            var defaultImageUrl = './static/ebay_default.jpg';
            // html for each single item:
            var singleHTML = "";
            singleHTML += "<table class='innerDetails' style='border: 1px solid #ccc'>";
            singleHTML += '<tr><td style="white-space: nowrap; padding-right: 10px;"><strong>Photo</strong></td><td><img src="' + photoUrl+ '"'+"onerror='this.src="+'"'+defaultImageUrl+'"'+"'"+' alt="' + defaultImageUrl + '"style="max-width: 200px;"/></td></tr>';
            singleHTML += '<tr><td style="white-space: nowrap; padding-right: 10px;"><strong>eBay Link</strong></td><td><a href='+itemUrl+' target="_blank">eBay Product Link</a></td></tr>';
            singleHTML += '<tr><td style="white-space: nowrap; padding-right: 10px;"><strong>Title</strong></td><td>' + title + '</td></tr>';
            singleHTML += '<tr><td style="white-space: nowrap; padding-right: 10px;"><strong>Price</strong></td><td>$' + price + '</td></tr>';
            singleHTML += '<tr><td style="white-space: nowrap; padding-right: 10px;"><strong>Location</strong></td><td>' + location + '</td></tr>';
            singleHTML += '<tr><td style="white-space: nowrap; padding-right: 10px;"><strong>Seller</strong></td><td>' + seller.UserID + '</td></tr>';
            singleHTML += '<tr><td style="white-space: nowrap; padding-right: 10px;"><strong>Return Policy(US)</strong></td><td>' + returnPolicy.ReturnsAccepted +' within '+ returnPolicy.ReturnsWithin +'</td></tr>';
            // loop through the item specifics
            for (var i = 0; i < itemSpecifics.length; i++) {
                singleHTML += '<tr><td style="white-space: nowrap; padding-right: 10px;"><strong>' + itemSpecifics[i].Name + '</strong></td><td>' + itemSpecifics[i].Value[0] + '</td></tr>';
            }


            singleHTML += "</table>";
            $("#search-results-single").html(singleHTML);
        }
        
        
    });
    




    var clearButton = document.getElementById("clearbutton");
    clearButton.addEventListener("click", function(){
        resultsHtml = "";
        clearForm();
        document.getElementById("search-results").innerHTML = ""
    });

    var searchButton = document.getElementById('searchbutton');
    searchButton.addEventListener('click', validatePriceRange);
    
});