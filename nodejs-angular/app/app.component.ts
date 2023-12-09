import { Component, OnInit, ChangeDetectorRef, OnDestroy, OnChanges,SimpleChanges } from '@angular/core';
import { HttpClient,HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { NgForm } from '@angular/forms';
import { finalize, switchMap,map } from 'rxjs/operators';
import { EMPTY, Subscription } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { FormControl } from '@angular/forms';
import { ItemService } from './item.service'; 
import { FormsModule, FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms'; // for reactive form
import { BehaviorSubject } from 'rxjs';
import { TruncatePipe } from './pipes/truncate.pipe';
import { environment } from '../environments/environment';

interface PostalCodeResponse {
  postalCodes: { postalCode: string }[];
}


@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css'],
  
})

//  implements OnInit
export class AppComponent implements OnChanges{


  private baseURL = environment.apiUrl;



  title = '';
  // data$!: Observable<any>; // Use the non-null assertion operator
  private _dataSubject = new BehaviorSubject<any>(null);
  public data$ = this._dataSubject.asObservable();
  private _lastSearchedKeyword: string = '';



  private _wishDataSubject = new BehaviorSubject<any>(null);
  public wishData$ = this._wishDataSubject.asObservable();

  highlightedIndex: number | null = null;

  highlightRow(index: number): void {
    this.highlightedIndex = index; 
  }
  selectedItem: any = null;

  searchKeyword: string = '';
  currentlocation: string = '';
  selectedCategory: string='All Categories';
  locationChoice: string = 'current';
  selectedOption: string = 'currentlocation';
  newCondition: boolean = false;
  usedCondition: boolean = false;
  unspecifiedCondition: boolean = false;
  localPickup: boolean = false;
  freeShipping: boolean = false;
  distanceMiles: number = 10;
  isInvalidKeyword: boolean = false;
  postal: string = ''; 
  isInvalidPostal: boolean = false;
  view: string = 'results'; //for the toggle
  progressbar: boolean = false;
  Math = Math;

  data!:any;

  itemsPerPage: number = 10;
  currentPage: number = 1;
  totalItems: number = 0; // temp
  pagedItems: any[]=[]; 
  totalPageNumbers: number[]=[];
  allItems: any[]=[];
  filteredOptions: any[] = [];
  showLargeImage = false;
  selectedImage: string = '';

  public wishlist :any[] = [];
  
  resultsData: any = null;
  wishListData: any = null;   



  photos: string[] = [];
  constructor(private http: HttpClient, private cdr: ChangeDetectorRef, private itemService: ItemService, changeDetectorRef: ChangeDetectorRef){}

  ngOnInit() {
    
    this.fetchWishData();
   

  }
  ngOnChanges(changes: SimpleChanges): void {
    // ...existing ngOnChanges code...
    if (this.selectedItemDetails?.Item?.ItemID) {
      this.fetchSimilarProducts(this.selectedItemDetails.Item.ItemID);
    }
  }
  
  itemExistsInMongoDB(item: any): Observable<boolean> {
 
  return this.http.get<boolean>(`${this.baseURL}/wishlist/exists/${item.id}`);
}

  enlargeImage(src: string) {
    this.selectedImage = src;
    this.showLargeImage = true;
  }
   
  onKeyUp(event: any) {
    if (event.target.value.length > 2) {
      this.getPostalOptions(event.target.value);
    }
  }

  getPostalOptions(query: string) {
    const API_URL = `http://api.geonames.org/postalCodeSearchJSON?postalcode_startsWith=${query}&maxRows=5&username=wlu98761&country=US`;
    
    this.http.get(API_URL).subscribe(
      (data: any) => {
        if (data && data.postalCodes) {
          this.filteredOptions = data.postalCodes;
        }
      },
      error => {
        
        console.error('Error fetching data from Geonames API', error);
        this.filteredOptions = [];
      }
    );
  
  }
// fetchData() {
//   // Check if data is already fetched, if so, return early
//   if (this.searchKeyword === this._lastSearchedKeyword && this._dataSubject.getValue()) {
//     return;
//   }

//   const conditionArray = [];

//     this.progressbar = true;
//     let params = new HttpParams()
//       .set('keywords', this.searchKeyword)
//       .set('category', this.selectedCategory)
//       .set('newCondition', this.newCondition)
//       .set('usedCondition', this.usedCondition)
//       .set('unspecifiedCondition', this.unspecifiedCondition) // Join the condition array with commas
//       .set('localPickup', this.localPickup.toString())
//       .set('freeShipping', this.freeShipping.toString())
//       .set('distanceMiles', this.distanceMiles.toString());

//   if (this.selectedOption === 'currentlocation') {
//     this.http.get('https://ipinfo.io?token=a92b2b800ba3b8').subscribe((data: any) => {
//       const zipCode = data.postal;
//       params = params.set('postal', zipCode);

//       this.http.get('http://localhost:3000/search', { params })
//         .pipe(finalize(() => this.progressbar = false))
//         .subscribe(response => {
//           // Push the fetched data to the BehaviorSubject
//           this._dataSubject.next(response);
//         });
//     });
//   } else {
//     this.http.get('http://localhost:3000/search', { params })
//       .pipe(finalize(() => this.progressbar = false))
//       .subscribe(response => {
//         // Push the fetched data to the BehaviorSubject
//         this._dataSubject.next(response);
//       });
//   }
//   this._lastSearchedKeyword = this.searchKeyword;
//   // this.fetchWishData();
// }

onOptionSelected() {

  this.isInvalidPostal = false;
  this.cdr.detectChanges(); 
}
  fetchData() {
    this.showResults = true;
    
    if (this.searchKeyword === this._lastSearchedKeyword && this._dataSubject.getValue()) {
          return;
        }
    const conditionArray = [];

    this.progressbar = true;
    let params = new HttpParams()
      .set('keywords', this.searchKeyword)
      .set('category', this.selectedCategory)
      .set('newCondition', this.newCondition)
      .set('usedCondition', this.usedCondition)
      .set('unspecifiedCondition', this.unspecifiedCondition) // Join the condition array with commas
      .set('localPickup', this.localPickup.toString())
      .set('freeShipping', this.freeShipping.toString())
      .set('distanceMiles', this.distanceMiles.toString());

    if (this.selectedOption === 'otherzip') {
      params =params.set('postal', this.postal);
    }
    console.log('I went here')
    if (this.selectedOption === 'currentlocation') {
      console.log('I went here too')
      this.http.get('https://ipinfo.io?token=a92b2b800ba3b8').subscribe((data: any) => {
        const zipCode = data.postal;
        console.log(zipCode)
        params = params.set('postal', zipCode);
      
        // this.data$ = this.http.get('http://localhost:3000/search', { params }).pipe(finalize(() => this.progressbar = false));  // Set loading to false when done
        // this.subscribeToData$();
        // this.data$.subscribe(response => {
        //   this.resultsData = response;
        this.http.get(`${this.baseURL}/search`, { params })
      .pipe(finalize(() => this.progressbar = false))
      .subscribe(response => {
        // Push the fetched data to the BehaviorSubject
        this._dataSubject.next(response);
    
        });
        console.log('I went here too')
   

      })
      
      ;
    }else{
    
      // this.data$ = this.http.get('http://localhost:3000/search', { params }).pipe(finalize(() => this.progressbar = false));  // Set loading to false when done
      // this.subscribeToData$();
      // this.data$.subscribe(response => {
      //   this.resultsData = response;
      this.http.get(`${this.baseURL}/search`, { params })
      .pipe(finalize(() => this.progressbar = false))
      .subscribe(response => {
        // Push the fetched data to the BehaviorSubject
        this._dataSubject.next(response);
     
      });
    }
    this._lastSearchedKeyword = this.searchKeyword;
    this.fetchWishData();
  };
  showResults=true;
  clearForm(){
    this.searchKeyword = '';
    this.selectedCategory = 'All Categories';
    this.newCondition = false;
    this.usedCondition = false;
    this.unspecifiedCondition = false;
    this.localPickup = false;
    this.freeShipping = false;
    this.distanceMiles = 10;
    this.selectedOption = 'currentlocation';
    this.postal = '';
    this.showResults = false;

    this.isInvalidKeyword = false;
    this.isInvalidPostal = false;
  }

  onInputChange() {
    // Check if the input is empty or contains only spaces
    // if (this.searchKeyword.trim() === '') {
    //   this.isInvalidKeyword = true;
    // } else {
    //   this.isInvalidKeyword = false;
    // }
    // if (this.selectedOption === 'otherzip') {
    //   if (!/^\d{5}$/.test(this.postal)) {
    //     this.isInvalidPostal = true;
    //   } else {
    //     this.isInvalidPostal = false;
    //   }
    // }
    this.isInvalidKeyword = !this.searchKeyword.trim();
    if (this.selectedOption === 'otherzip') {
      this.isInvalidPostal = !(/^\d{5}$/.test(this.postal.trim()));
    }
    this.cdr.detectChanges();
  
  }
//   ngOnInit(){
//     if (this.selectedOption === 'currentlocation') {
//       // If "Current Location" is selected by default, fetch the zip code based on the user's location
//       this.fetchZipCodeFromIPInfo();
//   }
// }
  updateSelectedOption(option: string) {
    // console.log('updateSelectedOption called with option:', option)
    // this.selectedOption = option;
    // if (option === 'currentlocation') {
    //   // Fetch location information using "ipinfo.io"
    //   this.fetchZipCodeFromIPInfo();
    // }
    this.selectedOption = option;

    // Reset the error state when the radio button is changed
    if (option === 'currentlocation') {
      this.isInvalidPostal = false;
      this.postal='';
    }else{
      this.onInputChange();
    }
    // this.onInputChange();
  }
  fetchZipCodeFromIPInfo() {
    this.http.get('https://ipinfo.io?token=a92b2b800ba3b8').subscribe((data: any) => {
      const zipCode = data.postal;
      this.postal = zipCode;
      console.log('Zip Code:', this.postal);
    });
  }
  isSearchButtonDisabled() {
    const isKeywordValid = !this.isInvalidKeyword;
    const isPostalValid = (this.selectedOption === 'currentlocation' || /^\d{5}$/.test(this.postal));
    return !(isKeywordValid && isPostalValid);
  }

  
  // for pagination

decrementPage() {
  if (this.currentPage > 1) {
    this.currentPage--;
  }
}

// incrementPage() {
//   //console.log("increment below");
//   //console.log( Math.ceil(this.data.findItemsAdvancedResponse[0].searchResult[0].item.length / this.itemsPerPage));
//   if (this.currentPage < Math.ceil(this.data.findItemsAdvancedResponse[0].searchResult[0].item.length / this.itemsPerPage)) {
//       this.currentPage++;
//   }
// }
incrementPage() {
  const data = this._dataSubject.getValue();

  if (data && this.currentPage < Math.ceil(data.findItemsAdvancedResponse[0].searchResult[0].item.length / this.itemsPerPage)) {
      this.currentPage++;
  }
}

subscribeToData$() {
  this.data$.subscribe(res => {
      this.data = res;
      console.log("Data:", this.data);
      // Handle the data further if needed
  });
}

shortTitle(title: string): string {
  // let shortTitle = title.substr(0, 35);
  // if (shortTitle[34] !== ' ') {
  //     shortTitle = shortTitle.substr(0, shortTitle.lastIndexOf(' '));
  // }
  // return shortTitle + "...";
  if (title.length > 35) {
    // Find the last space within the first 35 characters
    let lastSpaceIndex = title.substring(0, 35).lastIndexOf(' ');
    // If there is a space, we cut the string up to the last space to avoid cutting words in half
    if (lastSpaceIndex > -1) {
      return title.substr(0, lastSpaceIndex) + "...";
    } else {
      // If there is no space, just cut at 35 characters
      return title.substr(0, 35) + "...";
    }
  }
  // If the title is 35 characters or less, return the full title
  return title;
}
isItemInWishList(item: any):boolean{
  //console.log('Checking item:', item, 'Is in wish list:', this.wishlist.some(wishlistItem => wishlistItem.itemId === item.itemId));
  return this.wishlist.some(wishlistItem => wishlistItem.itemId === item.itemId);
  //  console.log('Checking item:', item);
  // const isInList = this.wishListData.some(wishlistItem => wishlistItem.itemId === item.itemId);
  // console.log('Is in wish list:', isInList);
  // return isInList;
  
}
// }
// isItemInWishList(item: any): boolean {
//   // Use the getValue method to synchronously retrieve the current value of the BehaviorSubject
//   const currentWishList: any[]= this._wishDataSubject.getValue();
//   // Perform the check using the current value
//   return currentWishList.some(wishlistItem => wishlistItem.itemId === item.itemId);
// }

isItemInWishList2(item: any):boolean{
  //console.log('Checking item:', item, 'Is in wish list:', this.wishlist.some(wishlistItem => wishlistItem.itemId === item.itemId));
  return this.wishlist.some(wishlistItem => wishlistItem.itemId === item.ItemId);
}

fetchWishData() {
  console.log("im at fetchWishData")
  this.itemService.getWishData().subscribe(response => {
    this._wishDataSubject.next(response);
    this.wishlist = response;
    // this.cdr.detectChanges();
  console.log(this.wishlist)
  });
}
// fetchWishData() {
// this.wishData$ = this.wishlistService.getWishList().pipe(
//   catchError(error => {
//     console.error('Error loading wishlist:', error);
//     return of([]); // Return an empty array or some error indication if there's an error
//   })
// );
// }

// fetchWishData(): void {
//   console.log("I'm at fetchWishData");
//   this.itemService.getWishData().subscribe((response: any[]) => {
//     // Process each item to have a short title for display purposes
//     const processedResponse = response.map(item => {
//       return {
//         ...item,
//         displayTitle: this.shortTitle(item.title) // Apply the shortTitle method here
//       };
//     });

//     // Update the BehaviorSubject with the new data
//     this._wishDataSubject.next(processedResponse);
//     // Update your local wishData array with the modified items for display
//     this.wishlist = response;
//     console.log(this.wishlist);
//   });
// }


addToWishList(item: any):void {
  //const index = this.wishlist.findIndex(wishlistItem => wishlistItem.itemId === item.itemId);
  const index = this.wishlist.findIndex(wishlistItem => wishlistItem.itemId === item.itemId);
  if (index > -1) {
      // Remove item from wishlist
      
      // this.wishlist.splice(index, 1);
      this.itemService.removeItemFromCart(item).subscribe(response => {
        console.log("Item removed from MongoDB successfully");
        this.fetchWishData();
    }, error => {
        console.log("Error removing item from MongoDB", error);
    });
  } else {
      // Extract currentPrice and shippingServiceCost
      let currentPrice = item.sellingStatus[0].currentPrice[0].__value__;
      let shippingServiceCost;
      if(item.shippingInfo && item.shippingInfo[0].shippingServiceCost) {
          shippingServiceCost = item.shippingInfo[0].shippingServiceCost[0].__value__;
      } else {
          shippingServiceCost = "N/A";
      }

      // Adjust the item before pushing it to the wishlist and sending to the backend
      item.currentPrice = currentPrice;
      item.shippingServiceCost = shippingServiceCost;

      // Add item to wishlist
      this.wishlist.push(item);
      // this.fetchWishData();
      console.log('Added to wishlist:', this.wishlist.length)

      // Save item to MongoDB
      this.itemService.addItemToCart(item).subscribe(response => {
          console.log(response);
          console.log("saved successfully");
          
      }, error => {
        if (error.status === 400 && error.error.message === 'Item already exists in the database') {
          console.log("Item already in the cart");
          // Optionally: Notify the user that the item is already in the cart.
      } else {
          console.log("Error adding item to the cart", error);
      }
      });
  }
  // this.fetchWishData();
  this.cdr.detectChanges(); 
}
// addToWishList(item: any): void {
//   const index = this.wishlist.findIndex(wishlistItem => wishlistItem.itemId === item.itemId);

//   if (index > -1) {
//     // Remove item from wishlist
//     this.itemService.removeItemFromCart(item).subscribe(response => {
//       console.log("Item removed from MongoDB successfully");
//       this.wishlist.splice(index, 1); // Remove item from the local array
//       this._wishDataSubject.next(this.wishlist); // Update the BehaviorSubject
//     }, error => {
//       console.log("Error removing item from MongoDB", error);
//     });
//   } else {
//     // Prepare the item with currentPrice and shippingServiceCost
//     let currentPrice = item.sellingStatus[0].currentPrice[0].__value__;
//     let shippingServiceCost = item.shippingInfo && item.shippingInfo[0].shippingServiceCost ?
//                               item.shippingInfo[0].shippingServiceCost[0].__value__ : "N/A";

//     // Adjust the item before pushing it to the wishlist
//     item.currentPrice = currentPrice;
//     item.shippingServiceCost = shippingServiceCost;
    
//     // Save item to MongoDB
//     this.itemService.addItemToCart(item).subscribe(response => {
//       console.log(response);
//       console.log("saved successfully");
//       // Add item to local wishlist array and update BehaviorSubject
//       this.wishlist.push(item);
//       this._wishDataSubject.next(this.wishlist); // Update the BehaviorSubject
//       // this.fetchWishData();
//       console.log('Added to wishlist:', this.wishlist.length)
//       console.log(this.isItemInWishList(item))
//     }, error => {
//       if (error.status === 400 && error.error.message === 'Item already exists in the database') {
//         console.log("Item already in the cart");
//         // Optionally: Notify the user that the item is already in the cart.
//       } else {
//         console.log("Error adding item to the cart", error);
//       }
//     });
//   }
//   // No need to call fetchWishData here
//   this.cdr.detectChanges(); // Inform Angular to detect changes
// }

addToWishList2(item: any):void {
  //const index = this.wishlist.findIndex(wishlistItem => wishlistItem.itemId === item.itemId);
  const index = this.wishlist.findIndex(wishlistItem => wishlistItem.itemId === item.ItemId);
  if (index > -1) {
      // Remove item from wishlist
      
      // this.wishlist.splice(index, 1);
      this.itemService.removeItemFromCart(item).subscribe(response => {
        console.log("Item removed from MongoDB successfully");
        this.fetchWishData();
    }, error => {
        console.log("Error removing item from MongoDB", error);
    });
  } else {
      // Extract currentPrice and shippingServiceCost
      let currentPrice = item.sellingStatus[0].currentPrice[0].__value__;
      let shippingServiceCost;
      if(item.shippingInfo && item.shippingInfo[0].shippingServiceCost) {
          shippingServiceCost = item.shippingInfo[0].shippingServiceCost[0].__value__;
      } else {
          shippingServiceCost = "N/A";
      }

      
      item.currentPrice = currentPrice;
      item.shippingServiceCost = shippingServiceCost;

      // Add item to wishlist
      this.wishlist.push(item);

      // Save item to MongoDB
      this.itemService.addItemToCart(item).subscribe(response => {
          console.log(response);
          console.log("saved successfully");
          // this.fetchWishData();
      }, error => {
        if (error.status === 400 && error.error.message === 'Item already exists in the database') {
          console.log("Item already in the cart");
          
      } else {
          console.log("Error adding item to the cart", error);
      }
      });
  }

  this.cdr.detectChanges(); // Inform Angular to detect changes
}
removeItemFromDatabase(item: any): void {
  console.log('removeItemFromDatabase triggered with item:', item);

  const index = this.wishlist.findIndex(wishlistItem => wishlistItem.itemId === item.itemId);
  if (index > -1) {
      // Remove item from wishlist
      this.wishlist.splice(index, 1);
      
      // Delete item from MongoDB
      this.itemService.removeItemFromCart(item.itemId).subscribe(response => {
          console.log(response);
          console.log("Item removed successfull 1");
          // this.fetchWishData();
      }, error => {
          console.log("Error removing item from the cart", error);
      });
  }
  
  this.cdr.detectChanges(); // Inform Angular to detect changes
}


// removeItemFromDatabase(item: any): void {
//   console.log('removeItemFromDatabase triggered with item:', item);
//   this.itemService.removeItemFromCart(item.itemId).subscribe(response => {
//     console.log(response);
//     console.log("Item removed successfully");
//     this.fetchWishData();
//   }, error => {
//     console.log("Error removing item from the cart", error);
//   });
//   this.cdr.detectChanges(); // Inform Angular to detect changes
// }


itemsInCart: any[] = [];

switchToWishView(): void {
  this.view = 'wish';
}

switchToResultsView(): void {
  this.view = 'results';
}

getTotalShippingCost(data: any[]): string {
  return data.reduce((acc, item) => {
    const shippingCost = parseFloat(item.currentPrice);
    if (isNaN(shippingCost)) {
      return acc;
    }
    return acc + shippingCost;
  }, 0).toFixed(2);
}


// Item Details Component:

isViewingDetails: boolean = false;
selectedItemDetails: any = {};
isDetailsButtonEnabled: boolean = false;


currentItemId: string =""
isCurrentItem(item: any): boolean {
  return this.currentItemId === item.itemId[0];
}

async fetchItemDetails(itemId: string) {
  try {
    this.currentItemId = itemId;
    const url = `${this.baseURL}/item/${itemId}`;
    this.selectedItemDetails = await this.http.get(url).toPromise();
    this.isViewingDetails = true;
    this.isDetailsButtonEnabled = true; // Enable the "Details" button
  } catch (error) {
    console.error('Failed to fetch item details:', error);
  }
}

showDetails(item: any) {
  this.fetchItemDetails(item.itemId[0]);  
}

showLastViewedDetails() {
  if (this.selectedItemDetails) {
      this.isViewingDetails = true;
  }
}
goBackToList() {
  this.isViewingDetails = false; // Reset the flag to show the search results table
   
}



showModal: boolean = false; 

selectedImageUrl: string='';
currentIndex: number = 0;

// Call this method when the modal is opened
openModal() {
  // this.selectedImageUrl = this.selectedItemDetails.Item.PictureURL[this.currentIndex];
  document.body.style.overflow = 'hidden';
  this.showModal = true;
}
currentImageIndex = 0;

previousImage() {
  if (this.currentImageIndex > 0) {
    this.currentImageIndex--;
  }
}

nextImage() {
  if (this.currentImageIndex < this.selectedItemDetails.Item.PictureURL.length - 1) {
    this.currentImageIndex++;
  }
}

closeModal() {
  document.body.style.overflow = 'auto';
  this.showModal = false;

}

// for other tabs

tabs: string[] = ['Product', 'Photos', 'Shipping', 'Seller', 'Similar Products'];
activeTab: string = 'Product';



selectTab(tab: string) {
  this.activeTab = tab;

  if (tab === 'Photos') {
    this.loadPhotos();
  }
  if (tab === 'Similar Products'){
    this.fetchSimilarProducts(this.selectedItemDetails.Item.ItemID);

  }
}


// for Shipping Tab:
selectItemDetail: any; // This holds the details of a specific item
matchedItemShippingInfo: any; 


getMatchedItemShippingInfo(itemId: string): Observable<any> {
  return this.data$.pipe(
    map(data => {
      const items = data?.findItemsAdvancedResponse?.[0]?.searchResult?.[0]?.item;
      const matchedItem = items?.find((item:any) => item.itemId[0] === itemId);
      return matchedItem ? matchedItem.shippingInfo : null;
    })
  );
}


sanitizeFeedbackRatingStar(ratingStar: string): string {
  // Remove 'Shooting' from the string
  return ratingStar.replace('Shooting', '').trim();
}

loadPhotos() {
  if (this.selectedItemDetails?.Item?.Title) {
    const itemTitle = this.selectedItemDetails.Item.Title;
    this.itemService.getPhotos(itemTitle).subscribe(
      data => {
        this.photos = data.images;
      },
      error => {
        console.error('There was an error retrieving the photos', error);
      }
    );
  }
}
// for photos tab:

// searchPhotos(itemTitle: string) {
//   this.itemService.getPhotos(itemTitle).subscribe(
//     data => {
//       this.photos = data.images;
     
//     },
//     error => {
//       console.error('There was an error retrieving the photos', error);
//     }
//   );
// }
// private subscriptions: Subscription[] = [];
similarProducts: any[] = [];
// private fetchSimilarProducts(itemId: string): void {

// }
// fetchSimilarProducts(itemId: string){
//   if (this.selectedItemDetails?.Item?.ItemID){
//     const itemID = this.selectedItemDetails.Item.ItemID;
//     this.itemService.getSimilarProducts(itemID).subscribe(
//       data => {
//         this.similarProducts = data.getSimilarItemsResponse.itemRecommendations.item;
//       },
//       error => {
//         console.error('There was an error retrieving similar items', error);
//       }
      
//     );
//     this.sortProducts();
//   }
  
// }

fetchSimilarProducts(itemId: string): void {
  this.sortedProducts = []; // Clear previous products

  this.itemService.getSimilarProducts(itemId).subscribe(
    data => {
      this.similarProducts = data.getSimilarItemsResponse.itemRecommendations.item;
      this.sortProducts();
    },
    error => {
      console.error('There was an error retrieving similar items', error);
    }
  );
}



extractDays(timeLeft: string): number {
  const match = timeLeft.match(/P(\d+)D/);
  return match ? parseInt(match[1],10) : 0;
}

sortCategory: string ='default';
sortOrder: string='asc';
sortedProducts: any[]=[];
sortProducts(): void {
  if (this.sortCategory === 'default') {
    this.sortedProducts = [...this.similarProducts];
    return;
  }

  this.sortedProducts = [...this.similarProducts].sort((a, b) => {
    let valueA, valueB;

    switch (this.sortCategory) {
      case 'productName':
        valueA = a.title;
        valueB = b.title;
        break;
      case 'daysLeft':
        valueA = this.extractDays(a.timeLeft);
        valueB = this.extractDays(b.timeLeft);
        break;
      case 'price':
        valueA = parseFloat(a.buyItNowPrice.__value__);
        valueB = parseFloat(b.buyItNowPrice.__value__);
        break;
      case 'shippingCost':
        valueA = parseFloat(a.shippingCost.__value__);
        valueB = parseFloat(b.shippingCost.__value__);
        break;
    }

    if (this.sortOrder === 'asc') {
      return valueA > valueB ? 1 : -1;
    } else {
      return valueA < valueB ? 1 : -1;
    }
  });
}



showAll: boolean = false;

toggleShowAll(): void {
  this.showAll = !this.showAll;
}
getDisplayedProducts(): any[] {
  if (this.showAll || this.sortedProducts.length <= 5) {
    return this.sortedProducts;
  }
  return this.sortedProducts.slice(0, 5); // Return only the first 5 products
}


getFacebookShareUrl(url: string): string {
  const fbShareUrl = 'https://www.facebook.com/sharer/sharer.php';
  return `${fbShareUrl}?u=${encodeURIComponent(url)}`;
}


// inner add wish list prior
getMatchedItemDetails(itemId: string): Observable<any> {
  return this.data$.pipe(
    map(data => {
      const items = data?.findItemsAdvancedResponse?.[0]?.searchResult?.[0]?.item;
      const matchedItem = items?.find((item: any) => item.itemId[0] === itemId);
      return matchedItem
    })
  );
}

public selectedItemR: any=null;
public selectItem(item: any): void {
  this.selectedItemR = this.selectedItemR === item ? null : item;
}
truncateTitle(title: string): string {
  const maxLength = 35;
  return title.length > maxLength ? title.substr(0, maxLength) + '...' : title;
}





formatStoreName(storeName: string): string {
  if (!storeName) return '';
  return storeName.toUpperCase();
}

// images: any[] = [];


// getImages(): void {
//   console.log("iam here triggered")
//   const title = this.selectedItemDetails.Item.Title; // Assuming selectedItemDetails is accessible
//   console.log(title);
//   this.http.get(`http://localhost:3000/api/images?title=${title}`).subscribe((data: any) => {
//     console.log(data)
//     this.images = this.chunkArray(data.items, 3);
//   });
  
// }

// chunkArray(arr: any[], chunkSize: number) {
//   const results = [];
//   while (arr.length) {
//     results.push(arr.splice(0, chunkSize));
//   }
//   return results;
// }
// loadImages(): void {
//   this.http.get<string[]>('/api/search-images', {
//     params: {
//       q: this.selectedItemDetails.Title,
//       imgSize: 'huge',
//       num: '8',
//     }
//   }).subscribe(
//     data => this.images = data,
//     error => console.error(error)
//   );
// }
// matchItemDetails() {
//   if (this.data && this.selectItemDetail && this.selectItemDetail.Item && this.selectItemDetail.Item.ItemID) {
//     // Finding the item from data that matches the ItemID from selectItemDetail
//     const matchedItem = this.data.findItemsAdvancedResponse[0].searchResult[0].item.find(item => 
//       item.itemId[0] === this.selectItemDetail.Item.ItemID
//     );
//     // If a match is found, extract the shipping info
//     this.matchedItemShippingInfo = matchedItem ? matchedItem.shippingInfo : null;
//   }
// }

// fetchItemsFromMongoDB() {
//   this.itemService.getItemsFromCart().subscribe(
//     (items: Object) => {
//       // Handle the retrieved items here
//       console.log('Items from MongoDB:', items);
//       // Assign the items to your component property to display them in the HTML
//       this.itemsInCart = items as any[];
//     },
//     (error) => {
//       console.error('Error fetching items from MongoDB', error);
//     }
//   );
// }



// addToWishList(item: any) {
//     const index = this.wishlist.findIndex(wishlistItem => wishlistItem.itemId === item.itemId);
//     if (index > -1) {
//         // Remove item from wishlist
//         this.wishlist.splice(index, 1);
//     } else {
//         // Add item to wishlist
//         this.wishlist.push(item);
//         // save item to MongoDB
//         this.itemService.addItemToCart(item).subscribe(response =>{
//           console.log(response);
          
//         },error =>{console.log("Error added item to the cart",error);})
//     }
//     this.cdr.detectChanges();  // Inform Angular to detect changes
//     //console.log(this.wishlist)
// }
  //   const index = this.wishlist.findIndex(wishlistItem => wishlistItem.itemId === item.itemId);
  
  //   if (index > -1) {
  //       // If item is already in the wishlist, remove it.
  //       this.wishlistService.removeFromWishlist(item.itemId).subscribe(response => {
  //           // Once removed from DB, update local list
  //           this.wishlist.splice(index, 1);
  //           this.cdr.detectChanges();
  //       },
  //       error => {
  //         console.error('Error removing item from wishlist:', error);
  //     });
  //   } else {
  //       // If item isn't in the wishlist, add it.
  //       this.wishlistService.addToWishlist(item).subscribe(response => {
  //           // Once added to DB, update local list
  //           this.wishlist.push(item);
  //           this.cdr.detectChanges();
  //       },
  //       error => {
  //         console.error('Error adding item to wishlist:', error);
  //     });
     
  //       console.log(this.wishlist)
  //   }
  // }




}
