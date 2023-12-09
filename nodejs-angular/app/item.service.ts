import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import {environment} from '../environments/environment';
@Injectable({
  providedIn: 'root'
})
export class ItemService {
  // private baseURL = 'http://localhost:3000';  
  private baseURL = environment.apiUrl;
  constructor(private http: HttpClient) { }

  addItemToCart(item: any) {
    return this.http.post(`${this.baseURL}/addItemToCart`, item);
  }
  getWishData(): Observable<any> {
    return this.http.get(`${this.baseURL}/wishData`);
  }
  removeItemFromCart(itemId: string) {
    return this.http.delete(`${this.baseURL}/removeItemFromCart/${itemId}`);
  }

getPhotos(itemTitle: string) {
  const url = `${this.baseURL}/searchPhotos`;
  return this.http.get<{ images: string[] }>(url, {
    params: { itemTitle: itemTitle } 
  });
}
getSimilarProducts(itemId: string): Observable<any> { // Response typed as 'any'
  const url = `${this.baseURL}/similarItems/${itemId}`;
  return this.http.get(url); 
}
}