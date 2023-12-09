//
//  ContentView.swift
//  ebay-search
//
//  Created by Will on 11/8/23.
//
 
import FBSDKShareKit
import Foundation
import SwiftUI
import CoreLocation
struct ContentView: View {
    @State private var isShowingLaunchScreen = true
    @StateObject var sharedData = SharedDataStore()
    @State private var showWishlistIcon = true

    var body: some View {
        Group {
                    if isShowingLaunchScreen {
                        LaunchScreenView()
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        isShowingLaunchScreen = false
                                    }
                                }
                            }
                    } else {
                        
                        NavigationView{
                            ProductSearchView(sharedData: sharedData, showWishlistIcon: $showWishlistIcon)
                        }
                      

                    }
                }
            }
}
class NavigationBarConfigurator: ObservableObject {
    @Published var showWishlistIcon: Bool = true
}

struct IPInfoResponse: Codable {
    let postal: String
}


class SharedDataStore: ObservableObject {
    @Published var items: [Item] = []
    func isItemInWishlist(itemId: String) -> Bool {
            return items.contains(where: { $0.id == itemId })
        }
}

struct ProductSearchView: View {
    
    @State private var wishlistMessage: String?

    @ObservedObject var sharedData: SharedDataStore
    @Binding var showWishlistIcon: Bool
    
    @State private var scrollOffset: CGFloat = 0

    @State private var showToolbar: Bool = false

    @State private var showZipCodeSuggestions = false

    


    @State private var keyword: String = ""
    @State private var selectedCategory = "All"
    @State private var conditionUsed = false
    @State private var conditionNew = false
    @State private var conditionUnspecified = false
    @State private var shippingPickup = false
    @State private var shippingFree = false
    @State private var customLocationEnabled = false
    @State private var zipCode: String = ""
    @State private var fetchedZipCode: String?
    @State private var distance = ""
    @State private var responseData :String?=nil
    @State private var isLoading = false
    
    @State private var suggestions: [String] = []
    @State private var showSuggestions: Bool = false
    //    for search results table item
    @State var items: [Item] = []
    @StateObject private var locationManager = LocationManager()
    
    @State private var searchPerformed = false
    
    @State private var showingWishList = false
    
    
    @State private var isActiveWishListLink = false

    
    @State private var errorMessage: String?

    // for item details
    @State private var selectedItemID: String?

    let categories = ["All","Art","Baby","Books","Clothing, Shoes & Accesories","Computers/Tablets & Networking","Health & Beauty","Music","Video Games & Consoles"]
    var body: some View {
        
        ZStack(alignment: .bottom){
            NavigationView {
                    Form {
                        
                        Section(header:titleCase(text:"Product search").background(GeometryReader { geometry in
                            Color.clear.onAppear {
                                updateToolbarVisibility(with: geometry.frame(in: .global).minY)
                            }
                            .onChange(of: geometry.frame(in: .global).minY) { newY in
                                updateToolbarVisibility(with: newY)
                            }
                        })) {
                                
                                
                                HStack {
                                    Text("Keyword:")
                                        .foregroundColor(.black)
                                    
                                    
                                    ZStack(alignment: .leading) {
                                        if keyword.isEmpty {
                                            Text("Required")
                                                .foregroundColor(.gray)
                                                .padding(.leading, 4)
                                        }
                                        TextField("", text: $keyword)
                                        
                                    }
                                }
                                
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(categories, id: \.self) {
                                        Text($0)
                                    }
                                }
                                .pickerStyle(.menu)
                                VStack(alignment: .leading){
                                    
                                    
                                    Text("Condition:").padding(.bottom,2)
                                    
                                    HStack {
                                        Spacer()
                                        Checkbox(isChecked: $conditionUsed, label: "Used")
                                        Checkbox(isChecked: $conditionNew, label: "New")
                                        Checkbox(isChecked: $conditionUnspecified, label: "Unspecified")
                                        Spacer()
                                    }
                                    
                                }
                                
                                VStack(alignment: .leading){
                                    
                                    
                                    Text("Shipping:").padding(.bottom,2)
                                    
                                    HStack {
                                        Spacer()
                                        Checkbox(isChecked: $shippingPickup, label: "Pickup")
                                        Checkbox(isChecked: $shippingFree, label: "Free Shipping")
                                        Spacer()
                                    }
                                }
                                
                                
                                HStack {
                                    Text("Distance:")
                                        .foregroundColor(.black)
                                    
                                    
                                    ZStack(alignment: .leading) {
                                        if distance.isEmpty {
                                            Text("10")
                                                .foregroundColor(.gray)
                                                .padding(.leading, 4)
                                        }
                                        TextField("", text: $distance)
                                    }
                                }
                            Toggle("Custom location", isOn: $customLocationEnabled)
                                    .onChange(of: customLocationEnabled) {
                                        
                                        if !customLocationEnabled {
                                            
                                            locationManager.start()
                                        }
                                        else{
                                            showZipCodeSuggestions = false
                                        }
                                    }
                                if customLocationEnabled {
                                    
                                    HStack{
                                        Text("Zipcode:")
                                            .foregroundColor(.black)
                                        
                                        
                                        ZStack(alignment: .leading) {
                                            if zipCode.isEmpty {
                                                Text("Required")
                                                    .foregroundColor(.gray)
                                                    .padding(.leading, 4)
                                            }
                                            TextField("", text: $zipCode)
                                                .onChange(of: zipCode) { newValue in
                                                    if newValue.count == 4 {
                                                        fetchZipCodeSuggestions(query: newValue)
                                                    } else {
                                                        suggestions = []
                                                        showZipCodeSuggestions = false
                                                    }
                                                }
                                                .sheet(isPresented: $showZipCodeSuggestions) {
                                                    ZipCodeSuggestionView(suggestions: $suggestions, selectedZipCode: $zipCode, isPresented: $showZipCodeSuggestions)
                                                }
                                        }
                                    }
                                }
                                HStack {
                                    Spacer()
                                    Button("Submit", action: submitAction).buttonStyle(CustomBorderedProminentButtonStyle())
                                    Spacer()
                                    Button("Clear", action: clearAction).buttonStyle(CustomBorderedProminentButtonStyle())
                                    
                                    Spacer()
                                }
                            }
                        
                        Section{

                            if isLoading {
                                
                                Text("Results").font(.system(size: 25))
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.top, 5)
                                    .padding(.bottom, 5)
                                
                                
                                //                            ProgressView("Please wait...")
                                VStack {
                                    ProgressView("Please wait...")
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gray)).id(UUID())
                                }
                                
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.white.opacity(0.5))
                                
                            }
                            
                            else if !isLoading && !items.isEmpty{
                                Text("Results")
                                    .font(.system(size: 25))
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.top, 5)
                                    .padding(.bottom, 5)
                                
                                ForEach(sharedData.items) { item in
                                    NavigationLink(destination: ItemDetailView(showWishlistIcon: $showWishlistIcon, itemId: item.id, sharedData: sharedData)) {
                                        ItemView(wishlistMessage: $wishlistMessage, sharedData: sharedData,item: item)
                                    }
                                    
                                }
                                
                            }
                            else if !isLoading && items.isEmpty && searchPerformed{
                                Text("Results")
                                    .font(.system(size: 25))
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.top, 5)
                                    .padding(.bottom, 5)
                                
                                Text("No results found.")
                                    .foregroundColor(.red)
                                
                            }
                            
                            
                            
                        }
                        
                        
                        
                    }
                   
                
                }
                .navigationBarTitle(showToolbar ? "Product search" : "", displayMode: .inline)

                if let errorMessage = errorMessage {
                    ErrorMessageView(message: errorMessage)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.errorMessage = nil
                            }
                        }
                }
                if let wishlistMessage = wishlistMessage {
                    ErrorMessageView(message: wishlistMessage)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.wishlistMessage = nil
                            }
                        }
                        .zIndex(1)
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 + 250)
                }
                
            }
            

            .navigationBarItems(trailing: HStack {
                
                if showWishlistIcon {
                    NavigationLink(destination: WishListView(), isActive: $isActiveWishListLink) {
                        
                        Image(systemName: "heart.circle")
                            .accessibilityLabel("Wish List")
                            .imageScale(.large)
                    }
                }
            })
        
    }
    
    func fetchZipCodeSuggestions(query: String) {
            guard let url = URL(string: "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/zipcodes?zipcode=\(query)") else { return }
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data, error == nil {
                    if let decodedResponse = try? JSONDecoder().decode([String].self, from: data) {
                        DispatchQueue.main.async {
                            self.suggestions = decodedResponse
                            self.showZipCodeSuggestions = true
                        }
                    }
                } else {
                    print("Error fetching zip code suggestions: \(error?.localizedDescription ?? "Unknown error")")
                }
            }.resume()
        }
    private func updateToolbarVisibility(with minY: CGFloat) {
            showToolbar = minY < 0
        }
    func submitAction() {
        
        
        if keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "Keyword is mandatory"
                isLoading = false
                return
        }
        
        
        items = []
        isLoading = true
        responseData = nil
        searchPerformed = true
        errorMessage = nil
        
        
        let originalDistance = distance

      
        let postalValue = customLocationEnabled ? zipCode : (locationManager.postalCode ?? "90007")

        // Construct the URL: the front end path!
        var urlComponents = URLComponents(string: "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/search")
        if distance.isEmpty {
                distance = "10"
            }
        var queryItems = [
            URLQueryItem(name: "keywords", value: keyword),
            URLQueryItem(name: "category", value: selectedCategory),
            URLQueryItem(name: "newCondition", value: conditionNew ? "true" : "false"),
            URLQueryItem(name: "usedCondition", value: conditionUsed ? "true" : "false"),
            URLQueryItem(name: "distanceMiles", value: distance),
            URLQueryItem(name: "postal", value: postalValue)
        ]

        if shippingFree {
            queryItems.append(URLQueryItem(name: "freeShipping", value: "true"))
        }
        if shippingPickup {
            queryItems.append(URLQueryItem(name: "localPickup", value: "true"))
        }

        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            print("Invalid URL")
            isLoading = false
            return
        }


        print(url) // test front end
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    responseData = "Error: \(error.localizedDescription)"
                } else if let data = data {
                    // Parse the JSON data
                    let decoder = JSONDecoder()
                    do {
                        let result = try decoder.decode(SearchResult.self, from: data)
                        self.items = result.findItemsAdvancedResponse.first?.searchResult.first?.item ?? []
                        sharedData.items = self.items
                    } catch {
                        print("Parsing error: \(error)")
                    }
                }
            }
        }.resume()

        distance = originalDistance
    }

    
    func clearAction() {
        isLoading = false
        responseData = nil
        keyword = ""
        selectedCategory = "All"
        conditionUsed = false
        conditionNew = false
        conditionUnspecified = false
        shippingPickup = false
        shippingFree = false
        customLocationEnabled = false
        distance = ""
        searchPerformed = false
        items = []
        errorMessage = nil
    }

    func titleCase(text: String) -> some View {
            HStack {
                Text(text)
                    .font(.system(size: 30))
                    .foregroundColor(.black)
                    .bold()
                    .textCase(.none)
                    .fontWeight(.bold)
                    .padding(.leading,-20)
                Spacer()
            }
           
        }
    
    private func displayTitle() -> String {
            if scrollOffset < -100 {
                return "Product Search"
            } else {
                return ""
            }
        }
    func fetchSuggestions(query: String) {
            let urlString = "http://api.geonames.org/postalCodeSearchJSON?postalcode_startsWith=\(query)&maxRows=5&username=wlu98761&country=US"
            guard let url = URL(string: urlString) else { return }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    if let decodedResponse = try? JSONDecoder().decode(GeoNamesResponse.self, from: data) {
                        DispatchQueue.main.async {
                            self.suggestions = decodedResponse.postalCodes.map { $0.postalCode }
                            self.showZipCodeSuggestions = true

//                            self.showSuggestions = !self.suggestions.isEmpty
                        }
                    }
                }
            }.resume()
    }
    
}



struct ZipCodeSuggestionView: View {
    @Binding var suggestions: [String]
    @Binding var selectedZipCode: String
    @Binding var isPresented: Bool
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                   
                    
                    listContentView
                }
            }
            .navigationTitle("Pincode Suggestions")
            .onAppear {
//                if !suggestions.isEmpty {
//                    isLoading = false
//                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isLoading = suggestions.isEmpty
                                }
            }
        }
    }

    private var listContentView: some View {
        List(suggestions, id: \.self) { suggestion in
            Button(action: {
                self.selectedZipCode = suggestion
                self.isPresented = false
            }) {
                Text(suggestion).foregroundColor(Color.black)
            }
        }
    }
}

struct CustomBorderedProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
    }
}


struct SearchResult: Codable {
    let findItemsAdvancedResponse: [FindItemsAdvancedResponse]
}

struct FindItemsAdvancedResponse: Codable {
    let searchResult: [SearchResultItem]
}

struct SearchResultItem: Codable {
    let item: [Item]
}

struct Item: Identifiable, Codable {
    
    
    

    let itemId: [String]
    let title: [String]
    let galleryURL: [String]
    let postalCode: [String]
    let sellingStatus: [SellingStatus]
    let condition: [ConditionItem]?
    let shippingInfo: [ShippingInfo]?
    let viewItemURL: [String]
    
    var id: String { itemId[0] }
    
    struct ShippingInfo: Codable {
            let shippingServiceCost: [ShippingCost]?
    }
    
    struct ShippingCost: Codable {
            let __value__: String?
    }
    
    struct SellingStatus: Codable {
        let currentPrice: [CurrentPrice]
    }

    struct CurrentPrice: Codable {
        let __value__: String
    }

    struct ConditionItem: Codable {
        let conditionDisplayName: [String]
    }
    
    
    var displayShippingCost: String {
            if let shippingCost = shippingInfo?.first?.shippingServiceCost?.first?.__value__,
               let cost = Double(shippingCost), cost > 0 {
                return "$\(cost)"
            } else {
                return "FREE SHIPPING"
            }
    }

    var displayTitle: String {
        title[0]
    }
    
    var imageURL: URL? {
        URL(string: galleryURL[0])
    }
    
    var displayPrice: String {
        sellingStatus[0].currentPrice[0].__value__
    }
    
    var displayCondition: String {
        condition?.first?.conditionDisplayName.first ?? "N/A"
    }
    
    var displayPostalCode: String {
        postalCode[0]
    }
    var displayViewItemURL: String? {
            viewItemURL.first
        }
}

struct ItemRequest: Codable {
    let itemId: String
    let galleryURL: String
    let title: String
    let currentPrice: Double
    let shippingServiceCost: Double
    let postalCode: String
    let condition: String
}

struct ItemView: View {
    @Binding var wishlistMessage: String?

    @ObservedObject var sharedData: SharedDataStore
    let item: Item
    @State private var isItemInWishlist = false
    var body: some View {
        
       
        HStack {
            AsyncImage(url: item.imageURL) { image in
                image.resizable()
            } placeholder: {
                ProgressView("Please wait...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray)).id(UUID())
            }
            .frame(width: 60, height: 60)
            
            VStack(alignment: .leading) {
                //                Text(item.displayTitle).lineLimit(1).truncationMode(/*@START_MENU_TOKEN@*/.tail/*@END_MENU_TOKEN@*/)
                
                
                
                Text(String(item.displayTitle.prefix(15)) + (item.displayTitle.count > 15 ? "..." : ""))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("$\(item.displayPrice)").foregroundColor(Color.blue).bold()
                Text(item.displayShippingCost).foregroundColor(Color.gray).lineLimit(1)
                
                HStack{
                    Text(item.displayPostalCode).foregroundColor(Color.gray)
                    Spacer()
                    Spacer()
                    Text(item.displayCondition)
                        .foregroundColor(Color.gray)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button(action: {
                Task {
                    
                    if isItemInWishlist {
                        
                        await removeItemFromWishlist()
                        DispatchQueue.main.async {
                            wishlistMessage = "Removed from favorites"
                        }

                    } else {
                        
                        await addItemToWishlist()
                        DispatchQueue.main.async {
                            wishlistMessage = "Added to favorites"
                        }

                    }
                }
            }) {
                Image(systemName: isItemInWishlist ? "heart.fill" : "heart")
                    .foregroundColor(isItemInWishlist ? .red : .red)
                    .imageScale(.large)
                    .frame(width: 44, height: 44)
                
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            Task {
                await checkIfItemInWishlist()
            }
            
        }
    }
    
    
    func checkIfItemInWishlist() async {
        guard let url = URL(string: "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/checkItemInWishlist?itemId=\(item.id)") else { return }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let isInWishlist = String(data: data, encoding: .utf8) == "true"
                DispatchQueue.main.async {
                    self.isItemInWishlist = isInWishlist
                }
            } catch {
                print("Error checking item in wishlist: \(error)")
            }
        }
    

    private func addItemToWishlist() async {
        guard let url = URL(string: "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/addItemToCart") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let itemDetails = ItemRequest(itemId: item.id, galleryURL: item.galleryURL[0], title: item.title[0], currentPrice: Double(item.displayPrice) ?? 0.0, shippingServiceCost: Double(item.displayShippingCost) ?? 0.0, postalCode: item.displayPostalCode, condition: item.displayCondition)

        do {
            request.httpBody = try JSONEncoder().encode(itemDetails)
        } catch {
            print("Failed to encode item")
            return
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to add item to wishlist")
                return
            }
            DispatchQueue.main.async {
                self.isItemInWishlist = true
            }
        } catch {
            print("Error adding item to wishlist: \(error)")
        }
    }


    func removeItemFromWishlist() async {
        guard let url = URL(string: "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/removeItemFromCart/\(item.id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    self.isItemInWishlist = false
                }
            } else if let error = error {
                print("Error removing item from wishlist: \(error)")
            }
        }.resume()
        
    }

        
    
    
}

struct GeoNamesResponse: Codable {
    let postalCodes: [PostalCodeInfo]
}

struct PostalCodeInfo: Codable {
    let postalCode: String
}

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)

            HStack(alignment: .center, spacing: 5) {
                Text("Powered by")
                    .font(.system(size: 24))
                    .foregroundColor(.black)

                Image("ebay")
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
    }
}
struct Checkbox: View {
    @Binding var isChecked: Bool
    var label: String

    var body: some View {
        Button(action: { self.isChecked.toggle() }) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? .blue : .gray)
                Text(label)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



struct ErrorMessageView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 20))
            .foregroundColor(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(Color.black)
            .cornerRadius(5)
            
        
    }
}

// /////////////////////////////////////////////////////////////////
// //////////////// Tab contents start from now! ///////////////////
// /////////////////////////////////////////////////////////////////
struct ShippingInfo {
    var storeName: String?
    var storeURL: String?
    var feedbackScore: Int?
    var positiveFeedbackPercent: Double?
    var shippingCost: String?
    var globalShipping: Bool
    var handlingTime: Int?
    var returnPolicy: String?
    var refundMode: String?
    var returnWithin: String?
    var shippingCostPaidBy: String?
}

struct PhotoResponse: Codable {
    var images: [String]
}

struct SimilarItem: Identifiable, Codable {
    var id: String
    var title: String
    var viewItemURL: String
    var imageURL: String
    var price: String
    var shippingCost: String
    var timeLeft: String

    enum CodingKeys: String, CodingKey {
        case id = "itemId"
        case title
        case viewItemURL
        case imageURL
        case timeLeft
        case price = "buyItNowPrice"
        case shippingCost
    }

    enum PriceKeys: String, CodingKey {
        case value = "__value__"
    }

    enum ShippingKeys: String, CodingKey {
        case value = "__value__"
    }

    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        viewItemURL = try container.decode(String.self, forKey: .viewItemURL)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        timeLeft = try container.decode(String.self, forKey: .timeLeft)

        let priceContainer = try container.nestedContainer(keyedBy: PriceKeys.self, forKey: .price)
        price = try priceContainer.decode(String.self, forKey: .value)

        let shippingContainer = try container.nestedContainer(keyedBy: ShippingKeys.self, forKey: .shippingCost)
        shippingCost = try shippingContainer.decode(String.self, forKey: .value)
    }
}
struct SimilarItemsResponse: Codable {
    let getSimilarItemsResponse: GetSimilarItemsResponse
}

struct GetSimilarItemsResponse: Codable {
    let itemRecommendations: ItemRecommendations
}

struct ItemRecommendations: Codable {
    let item: [SimilarItem]
}


enum SortOption: String, CaseIterable {
    case `default`, name, price, daysLeft, shipping
}

enum SortOrder: String, CaseIterable {
    case ascending, descending
}



 // fb sharing/////////////////////////////////////////////////////////

struct ItemDetailView: View {
    @Binding var showWishlistIcon: Bool

    let itemId: String
    @ObservedObject var sharedData: SharedDataStore
    
    @State private var item: Item?
    
    @State private var jsonDetails: String?
    @State private var isLoading = true
    @State private var isLoadingPhoto = true

    @State private var errorMessage: String?
    @State private var title: String = ""
    @State private var viewItemURLForNaturalSearch: String?
    @State private var price: String = ""
    @State private var imageURLs: [String] = []
//    @State private var itemSpecifics: String = ""
    @State private var itemSpecifics: [(key: String, value: String)] = []
    @State private var similarItems: [SimilarItem] = []
    @State private var selectedTab = 0
    @State private var selectedSortOption: SortOption = .default
    @State private var sortOrder: SortOrder = .ascending
    
    @State private var shippingDetails: ShippingInfo?
    
    @State private var shippingCost: Double = 0.0
    @State private var postalCode: String = ""
    @State private var condition: String = ""
    
    @State private var isItemInWishlist = false

    @State private var isLoadingShippingDetails = true

    @Environment(\.presentationMode) var presentationMode

    var body: some View{
        VStack {
                    
                    Group {
                        switch selectedTab {
                        case 0:
                            infoView
                        case 1:
                            shippingView
                        case 2:
                            photosView
                        case 3:
                            VStack{
                                sortView
                                similarItemsView
                            }
                           
                        default:
                            Text("Unknown Tab")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Tab bar
                    TabBarView(selectedTab: $selectedTab)
                }
        .navigationBarItems(trailing: HStack {
            facebookShareButton
            addToWishlistButton
        })
        
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Product search")
            }
        })
        

        .onAppear {
            Task {
                await fetchItemDetails()
                isLoadingShippingDetails = false

                await checkIfItemInWishlist()
                }
            self.showWishlistIcon = false
            
            }
        .onDisappear{
            self.showWishlistIcon = true
            }
                
        .edgesIgnoringSafeArea(.bottom)
                
    }

    var shippingView: some View {
//        Text("gai")
        
        ZStack{
            if isLoadingShippingDetails {
                        VStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.5)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            VStack() {
                                if let shippingInfo = shippingDetails {
                                    Group {
                                        if shippingInfo.storeName != nil || shippingInfo.feedbackScore != nil || shippingInfo.positiveFeedbackPercent != nil {
                                            Divider()
                                            HStack{
                                                Image(systemName: "storefront")
                                                
                                                Text("Seller Information")
                                                Spacer()
                                            }.padding(.leading,40)
                                            
                                            Divider()
                                            
                                            if let storeName = shippingInfo.storeName, let storeURL = shippingInfo.storeURL {
                                                HStack{
                                                    Text("Store Name")
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding(.leading)
                                                    Spacer()
                                                    Link(storeName, destination: URL(string: storeURL)!).frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding([.trailing])
                                                }
                                                
                                            }
                                            
                                            if let feedbackScore = shippingInfo.feedbackScore {
                                                
                                                HStack{
                                                    Text("Feedback Score")
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding(.leading)
                                                    Spacer()
                                                    Text("\(feedbackScore)").frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding([.trailing])
                                                }
                                                
                                                
                                            }
                                            if let popularity = shippingInfo.positiveFeedbackPercent {
                                                let popularityString = String(format: "%.2f", popularity)
                                                
                                                HStack{
                                                    Text("Popularity")
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding(.leading)
                                                    Spacer()
                                                    Text("\(popularityString)")
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding([.trailing])
                                                }
                                    
                                            }
                                        }
                                    }
                                    
                                    Group {
                                        
                                        if shippingInfo.shippingCost != nil ||
                                            shippingInfo.globalShipping != nil ||
                                            shippingInfo.handlingTime != nil{
                                            Divider()
                                            HStack{
                                                Image(systemName: "sailboat")
                                                Text("Shipping Info").font(.headline)
                                                Spacer()
                                            }.padding(.leading,40)
                                            Divider()
                                            
                                            
                                            if let shippingCost = shippingInfo.shippingCost {
                                                
                                                HStack{
                                                    Text("Shipping Cost").frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding(.leading)
                                                    Spacer()
                                                    Text(shippingCost)
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding([.trailing])
                                                    
                                                }
                                            }
                                            
                                            
                                            HStack{
                                                Text("Global Shipping").frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding(.leading)
                                                Spacer()
                                                Text(shippingInfo.globalShipping ? "Yes" : "No")
                                                    .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding([.trailing])
                                            }
                                            
                                            
                                            if let handlingTime = shippingInfo.handlingTime {
                                                
                                                HStack{
                                                    Text("Handling Time").frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding(.leading)
                                                    Spacer()
                                                    
                                                    Text("\(handlingTime) \(handlingTime <= 1 ? "day" : "days")")
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding([.trailing])
                                                    
                                                    
                                                }
                                            }
                                            
                                        }
                                    }
                                    Group {
                                        
                                        if shippingInfo.returnPolicy != nil ||
                                            shippingInfo.refundMode != nil ||
                                            shippingInfo.returnWithin != nil ||
                                            shippingInfo.shippingCostPaidBy != nil{
                                            Divider()
                                            HStack(){
                                                Image(systemName: "return")
                                                Text("Return Policy")
                                                Spacer()
                                            }.padding(.leading,40)
                                            
                                            Divider()
                                            
                                            
                                            if let returnPolicy = shippingInfo.returnPolicy {
                                                
                                                HStack {
                                                    Text("Policy")
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding(.leading)
                                                    Spacer()
                                                    Text(returnPolicy)
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding([.trailing])
                                                }
                                                
                                            }
                                            if let refundMode = shippingInfo.refundMode{
                                                HStack {
                                                    Text("Refund Mode")
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding(.leading)
                                                    Spacer()
                                                    Text(refundMode)
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding([.trailing])
                                                }
                                            }
                                            if let returnWithin = shippingInfo.returnWithin {
                                                
                                                HStack {
                                                    Text("Refund Within")
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding(.leading)
                                                    Spacer()
                                                    Text(returnWithin)
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding([.trailing])
                                                }
                                            }
                                            if let shippingCostPaidBy = shippingInfo.shippingCostPaidBy {
                                                
                                                HStack {
                                                    Text("Shipping Cost Paid By")
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding(.leading)
                                                    Spacer()
                                                    Text(shippingCostPaidBy)
                                                        .frame(width: UIScreen.main.bounds.width / 2, alignment: .center).padding([.trailing])
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    Text("Shipping details not available")
                                }
                            }
                            .padding()
                        }
            }
        }
    }
    var photosView: some View {
        ZStack {
            VStack {
                HStack(spacing: 5) {
                    Text("Powered by")
                        .font(.system(size: 20))
                        .foregroundColor(.black)

                    Image("google")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                }
                .padding([.top, .leading, .trailing])


                ScrollView {
                    VStack {
                        ForEach(imageURLs, id: \.self) { url in
                            AsyncImage(url: URL(string: url)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 200, height: 200)
                                        .cornerRadius(10)
                                case .failure(_):
                                    Image(systemName: "photo")
                                        .frame(width: 200, height: 200)
                                case .empty:
                                    ProgressView()
                                        .frame(width: 200, height: 200)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .padding()
                        }
                    }
                }
            }

            if isLoadingPhoto {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray)).id(UUID())
            }
        }
    }

    var sortView: some View {
            VStack {
                Text("Sort By").frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.bold).padding(20)
                Picker("Sort By", selection: $selectedSortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                }
                
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 360)
                .onChange(of: selectedSortOption) { _ in sortSimilarItems()
                }

                if selectedSortOption != .default {
                    Text("Order").frame(maxWidth: .infinity, alignment: .leading)
                        .fontWeight(.bold).padding(20)
                    Picker("Order", selection: $sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue.capitalized).tag(order)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 360)
                    .onChange(of: sortOrder) { _ in sortSimilarItems() }
                }
            }
         
        }


    var similarItemsView: some View {
        
        return
        ZStack{
            ScrollView {
                
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            .padding(.top, 200)
        
                        Spacer()
                    }
                    
                }
                else{
                    let gridItemSize = UIScreen.main.bounds.width / 2 - 20
                    let imageSize: CGFloat = 150
                    
                    LazyVGrid(columns: [GridItem(.fixed(gridItemSize)), GridItem(.fixed(gridItemSize))], spacing: 20) {
                        ForEach(similarItems, id: \.id) { item in
                            ZStack(alignment: .bottomTrailing) {
                                VStack {
                                    AsyncImage(url: URL(string: item.imageURL)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable().aspectRatio(contentMode: .fit)
                                                .frame(width: imageSize, height: imageSize)
                                            
                                        case .failure(_):
                                            Image(systemName: "photo").resizable()
                                                .frame(width: imageSize, height: imageSize)
                                            
                                        case .empty:
                                            ProgressView("Please wait...")
                                                .progressViewStyle(CircularProgressViewStyle(tint: .gray)).id(UUID())
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }.padding([.top,.horizontal],20)
                                        .frame(width: gridItemSize, height: gridItemSize)
                                        .cornerRadius(10)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title)
                                            .lineLimit(2)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding([.horizontal])
                                        HStack{
                                            Text("$\(item.shippingCost)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            Spacer()
                                            if let days = extractDays(from: item.timeLeft){
                                                Text("\(days) days left")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                        }.padding()
                                    }
                                    HStack{
                                        Spacer()
                                        Text("$\(item.price)")
                                            .fontWeight(.bold)
                                            .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                                            .padding([.top,.bottom, .trailing])
                                    }
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray, lineWidth: 2)
                            )
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                fetchSimilarItems()
            }
          
        }
        
        
        
    }
    var infoView: some View {
        
        VStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray)).id(UUID())
                        .padding(.top, 60)
                }
                else {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        VStack(alignment: .leading, spacing: 20) {
                            
                            TabView {
                                ForEach(imageURLs, id: \.self) { urlString in
                                    if let url = URL(string: urlString) {
                                        AsyncImage(url: url) { image in
                                            image.resizable()
                                        } placeholder: {
                                            Color.gray.frame(width: 60, height: 60)
                                        }
                                        .frame(width: 300, height: 300)
                                        .cornerRadius(10)
                                        .padding()
                                    }
                                }
                            }
                            .tabViewStyle(PageTabViewStyle())
                            .frame(height: 300)
                            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))}
                        Text(title).fixedSize(horizontal: false, vertical: true)
                        
                        Text(price)
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        // Description
                        HStack{
                            Image(systemName: "magnifyingglass")
                            Text("Description")
                            
                        }
                    }
                    .padding(.horizontal)

                    ScrollView{
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Divider()
                            ForEach(itemSpecifics, id: \.key) { specific in
                                HStack {
                                    Text(specific.key)
                                        .frame(width:  UIScreen.main.bounds.width / 2, alignment: .leading)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text(specific.value)
                                        .frame(maxWidth: UIScreen.main.bounds.width / 2, alignment: .leading)
                                }
                                Divider()
                            }
                        }
                        .padding(.bottom)
                    }
                    .padding(.horizontal)
                    
                }
            
            }
        }
    struct TabBarView: View {
            @Binding var selectedTab: Int

            var body: some View {
                HStack {
                    Button(action: { self.selectedTab = 0 }) {
                        VStack {
                            
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 24))

                            Text("Info")
                                .font(.system(size: 12))

                        }
                        .foregroundColor(self.selectedTab == 0 ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)

                    Button(action: { self.selectedTab = 1 }) {
                        VStack {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 24))

                            Text("Shipping")
                                .font(.system(size: 12))

                            
                        }
                        .foregroundColor(self.selectedTab == 1 ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(action: { self.selectedTab = 2 }) {
                        VStack {
                            Image(systemName: "photo.stack.fill")
                                .font(.system(size: 24))

                            Text("Photos")
                                .font(.system(size: 12))

                        }
                        .foregroundColor(self.selectedTab == 2 ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)

                    Button(action: { self.selectedTab = 3 }) {
                        VStack {
                            Image(systemName: "list.bullet.indent")
                                .font(.system(size: 24))

                            Text("Similar")
                                .font(.system(size: 12))

                        }
                        .foregroundColor(self.selectedTab == 3 ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .onAppear()
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 5)
            }
        }
    
    var addToWishlistButton: some View {
        Button(action: {
            Task {
//                            await addItemToWishlist()
                if isItemInWishlist {
                    await removeItemFromWishlist()
                } else {
                    await addItemToWishlist()
                }
        }
        }) {
            Image(systemName: isItemInWishlist ? "heart.fill" : "heart")
                .foregroundColor(isItemInWishlist ? .red : .red)
                .imageScale(.large)
        }
    }

    var facebookShareButton: some View {
        Group {
            if let viewItemURL = viewItemURLForNaturalSearch {
                let encodedViewItemURL = viewItemURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let facebookShareURL = "http://www.facebook.com/sharer.php?u=\(encodedViewItemURL)"

                Link(destination: URL(string: facebookShareURL)!) {
                    Image("fb")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
            } else {
                Image("fb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }
        }
    }

    func addItemToWishlist() async{
       
//        guard !isItemInWishlist else { return }
//        let itemDetails = CartItem(itemId: itemId, galleryURL: imageURLs.first ?? "", title: title, currentPrice: Double(price) ?? 10, shippingServiceCost: shippingCost, postalCode: postalCode, condition: condition)
        
//        print("Shared Data Item IDs: \(sharedData.items.map { $0.id })")
//           print("Looking for Item ID: \(itemId)")
        guard let itemToAdd = sharedData.items.first(where: { $0.id == itemId }) else {
                print("Item not found in shared data")
                return
            }

            guard !isItemInWishlist else { return }

            guard let currentPrice = Double(itemToAdd.displayPrice) else {
                print("Cannot convert price to Double")
                return
            }

            
            let shippingCostString = itemToAdd.shippingInfo?.first?.shippingServiceCost?.first?.__value__
            let shippingServiceCost = Double(shippingCostString ?? "0") ?? 0

            
            let itemDetails = CartItem(
                itemId: itemToAdd.id,
                galleryURL: itemToAdd.imageURL?.absoluteString ?? "",
                title: itemToAdd.displayTitle,
                currentPrice: currentPrice,
                shippingServiceCost: shippingServiceCost,
                postalCode: itemToAdd.displayPostalCode,
                condition: itemToAdd.displayCondition
            )
        print(itemDetails)
        guard let url = URL(string: "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/addItemToCart") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(itemDetails)
            print("----")
            if let jsonData = request.httpBody, let jsonString = String(data: jsonData, encoding: .utf8) {
                print("JSON String: \(jsonString)")}
        } catch {
            print("Error encoding item details: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    self.isItemInWishlist = true
                }
            } else if let error = error {
                print("Error adding item to wishlist: \(error)")
            }
        }.resume()
    }
       
    func removeItemFromWishlist() async {
        guard let url = URL(string: "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/removeItemFromCart/\(itemId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                DispatchQueue.main.async {
                    self.isItemInWishlist = false
                }
            } else if let error = error {
                print("Error removing item from wishlist: \(error)")
            }
        }.resume()
    }
    func checkIfItemInWishlist() async {
            guard let url = URL(string: "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/checkItemInWishlist?itemId=\(itemId)") else { return }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let isInWishlist = String(data: data, encoding: .utf8) == "true"
                DispatchQueue.main.async {
                    self.isItemInWishlist = isInWishlist
                }
            } catch {
                print("Error checking item in wishlist: \(error)")
            }
        }
    func fetchSimilarItems() {
 
        isLoading = true
        
        guard let url = URL(string: "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/similarItems/\(itemId)") else {
            print("Invalid URL")
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let decodedResponse = try decoder.decode(SimilarItemsResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.similarItems = decodedResponse.getSimilarItemsResponse.itemRecommendations.item
                    }
                } catch {
                    print("Decoding error: \(error)")
                }
            } else if let error = error {
                print("HTTP error: \(error)")
            }
            isLoading = false
        }.resume()

    }
    func sortSimilarItems() {
        switch selectedSortOption {
        case .name:
            similarItems.sort { sortOrder == .ascending ? $0.title < $1.title : $0.title > $1.title }
        case .price:
            similarItems.sort { sortOrder == .ascending ? Double($0.price) ?? 0 < Double($1.price) ?? 0 : Double($0.price) ?? 0 > Double($1.price) ?? 0 }
        case .daysLeft:
            similarItems.sort {
                sortOrder == .ascending ?
                    parseDaysLeft($0.timeLeft) < parseDaysLeft($1.timeLeft) :
                    parseDaysLeft($0.timeLeft) > parseDaysLeft($1.timeLeft)
            }
        case .shipping:
            similarItems.sort { sortOrder == .ascending ? Double($0.shippingCost) ?? 0 < Double($1.shippingCost) ?? 0 : Double($0.shippingCost) ?? 0 > Double($1.shippingCost) ?? 0 }
        case .default:
            break
        }
    }

    func parseDaysLeft(_ timeLeft: String) -> Int {
        let timeComponents = timeLeft.split(whereSeparator: { !$0.isNumber })
        guard let dayComponent = timeComponents.first else { return Int.max }
        return Int(dayComponent) ?? Int.max
    }


    func fetchItemDetails() async {
        isLoading = true
        let baseURL = "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/item/\(itemId)"
        guard let url = URL(string: baseURL) else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data {
                    self.jsonDetails = String(data: data, encoding: .utf8)
                    parseJsonDetails()

                } else if let error = error {
                    self.errorMessage = "HTTP error: \(error.localizedDescription)"
                }
            }
        }.resume()
        fetchSimilarPhotos()
    }
    
    
    func fetchSimilarPhotos() {
        isLoading = true

        guard let url = URL(string: "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/searchPhotos?itemTitle=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            self.errorMessage = "Invalid URL for photos"
            isLoadingPhoto = false

            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode(PhotoResponse.self, from: data)
                        self.imageURLs = decodedResponse.images
                    } catch {
                        self.errorMessage = "JSON error: \(error.localizedDescription)"
                    }
                } else if let error = error {
                    self.errorMessage = "HTTP error: \(error.localizedDescription)"
                }
                isLoadingPhoto = false

            }

        }.resume()
    }

    func extractDays(from duration: String) -> Int? {
        guard duration.first == "P" && duration.contains("D") else { return nil }

        if let dayRangeStart = duration.firstIndex(of: "P"),
           let dayRangeEnd = duration.firstIndex(of: "D") {
            let daySubstring = duration[duration.index(after: dayRangeStart)..<dayRangeEnd]
            return Int(daySubstring)
        }

        return nil
    }
    

    // this parse is for Info Tab
    func parseJsonDetails() {
        guard let jsonData = jsonDetails?.data(using: .utf8) else { return }
        do {
            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let item = jsonDict["Item"] as? [String: Any] {
                // Extract title
                if let titleString = item["Title"] as? String {
                    self.title = titleString
                }

                // Extract price
                if let convertedCurrentPrice = item["ConvertedCurrentPrice"] as? [String: Any],
                   let value = convertedCurrentPrice["Value"] as? Double {
                    self.price = String(format: "$%.2f", value)
                }

                // Extract image URLs
                if let pictureURL = item["PictureURL"] as? [String] {
                    self.imageURLs = pictureURL
                }
                
                if let viewItemURLForNaturalSearch = item["ViewItemURLForNaturalSearch"] as? String {
                               
                                self.viewItemURLForNaturalSearch = viewItemURLForNaturalSearch
                }
             

                if let itemSpecificsDict = item["ItemSpecifics"] as? [String: Any],
                              let nameValueList = itemSpecificsDict["NameValueList"] as? [[String: Any]] {
                               self.itemSpecifics = nameValueList.compactMap { dict -> (key: String, value: String)? in
                                   guard let name = dict["Name"] as? String,
                                         let value = (dict["Value"] as? [String])?.joined(separator: ", ") else { return nil }
                                   return (key: name, value: value)
                        }
                }
                // Parse Shipping Info
                let storefront = item["Storefront"] as? [String: Any]
                let seller = item["Seller"] as? [String: Any]
                let returnPolicy = item["ReturnPolicy"] as? [String: Any]
                self.shippingDetails = ShippingInfo(
                    storeName: storefront?["StoreName"] as? String,
                    storeURL: storefront?["StoreURL"] as? String,
                    feedbackScore: seller?["FeedbackScore"] as? Int,
                    positiveFeedbackPercent: seller?["PositiveFeedbackPercent"] as? Double,
                    shippingCost: (item["GlobalShipping"] as? Bool ?? false) ? "Free" : "Varies",
                    globalShipping: item["GlobalShipping"] as? Bool ?? false,
                    handlingTime: item["HandlingTime"] as? Int,
                    returnPolicy: returnPolicy?["ReturnsAccepted"] as? String,
                    refundMode: returnPolicy?["Refund"] as? String,
                    returnWithin: returnPolicy?["ReturnsWithin"] as? String,
                    shippingCostPaidBy: returnPolicy?["ShippingCostPaidBy"] as? String
                )
                
                
                if let shippingCostValue = item["ShippingCost"] as? Double {
                                self.shippingCost = shippingCostValue
                            }
                self.postalCode = item["PostalCode"] as? String ?? ""
                self.condition = item["ConditionDisplayName"] as? String ?? ""
            }
        } catch {
            self.errorMessage = "JSON parsing error: \(error.localizedDescription)"
        }
        
        
        
    }
    
}




// add to cart/////////////////////////////////////////////////////////////////////////
struct CartItem: Codable {
    let itemId: String
    let galleryURL: String
    let title: String
    let currentPrice: Double
    let shippingServiceCost: Double
    let postalCode: String
    let condition: String
}


// Wish List///////////////////////////////////////////////////////////////////////////

struct WishItem: Identifiable, Codable {
    var id: String
    var itemId: String
    var galleryURL: String
    var title: String
    var currentPrice: Double?
    var shippingServiceCost: Double?
    var postalCode: String?
    var condition: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case itemId
        case galleryURL
        case title
        case currentPrice
        case shippingServiceCost
        case postalCode
        case condition
        
    }
}


struct WishlistItemView: View {
    var item: WishItem

    var body: some View {
        HStack {
            AsyncImage(url: URL(string: item.galleryURL)) { image in
                image.resizable()
            } placeholder: {
                Color.gray.frame(width: 60, height: 60)
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)

            VStack(alignment: .leading) {
                
                
                
                Text(String(item.title.prefix(25)) + (item.title.count > 25 ? "..." : ""))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
//                Text(item.title)
//                    .fontWeight(.semibold)
                Text("$\(item.currentPrice ?? 0, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .bold()
                
                Text("$\(item.shippingServiceCost ?? 0, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                
                
                HStack{
                    if let postalCode = item.postalCode, !postalCode.isEmpty {
                        Text("\(postalCode)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("\(item.condition ?? "N/A")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                }
                
             
            }
            Spacer()
        }
        
    }
}

    struct WishListView: View {
        @State private var wishListItems: [WishItem] = []
        @State private var isLoading = true
        @Environment(\.presentationMode) var presentationMode
        
        var totalWishlistPrice: Double {
            wishListItems.reduce(0) { sum, item in
                sum + (item.currentPrice ?? 0)
            }
        }

        var body: some View {
            Group {
                if wishListItems.isEmpty {
                    emptyWishlistView
                } else {
                    wishlistView
                }
            }
            .onAppear {
                fetchWishListItems()
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            })
                                {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Product search")
                }
            })
        }

        private var backButton: some View {
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Product search")
                }
            }
        }

        private var emptyWishlistView: some View {
            
            
            
            VStack {
                HStack {
                    Text("Favorites")
                        .font(.system(size: 30))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .textCase(nil)
                        .padding(.leading, 20)
                        .padding(.top, 17)
                    Spacer()
                }
                Spacer()
                Text("No items in wishlist")
                Spacer()
            }
        }

        private var wishlistView: some View {
            List {
                Section(header: titleCase(text: "Favorites")) {
                    VStack {
                        HStack {
                            Text("Wishlist total(\(wishListItems.count)) items: ")
                            Spacer()
                            Text("$\(totalWishlistPrice, specifier: "%.2f")")
                        }
                    }
                    
                    ForEach(wishListItems, id: \.id) { item in
                        WishlistItemView(item: item)
                    }
                    .onDelete(perform: deleteItemFromWishlist)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Please wait...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                }
            }
        }

            
        
    
    
    func titleCase(text: String) -> some View {
            HStack {
                Text(text)
                    .font(.system(size: 30))
                    .foregroundColor(.black)
                    .bold()
                    .textCase(.none)
                    .fontWeight(.bold)
                    .padding(.leading,-20)
                Spacer()
            }
           
        }
    private func fetchWishListItems() {
        guard let url = URL(string: "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/wishData") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let data = data, !data.isEmpty {
                    do {
                        let decodedItems = try JSONDecoder().decode([WishItem].self, from: data)
                        wishListItems = decodedItems
                    } catch {
                        print("Error decoding data: \(error)")
                    }
                } else if let error = error {
                    print("Error loading data: \(error.localizedDescription)")
                } else {
                    print("Received empty data or data could not be read")
                }
            }
        }.resume()
    }

    private func deleteItemFromWishlist(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let itemToDelete = wishListItems[index]
        wishListItems.remove(atOffsets: offsets)

        guard let url = URL(string: "http://ebay-search-hw4.us-east-1.elasticbeanstalk.com/removeItemFromCart/\(itemToDelete.itemId)") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error removing item from wishlist: \(error.localizedDescription)")
            } else {
                print("Item successfully removed from wishlist")
            }
        }.resume()
    }
}


#Preview {
    ContentView()

    
}
