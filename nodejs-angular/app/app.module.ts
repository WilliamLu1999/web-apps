import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HttpClientModule, HttpClient } from '@angular/common/http'; // Import HttpClientModule
import { FormsModule } from '@angular/forms';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { finalize } from 'rxjs/operators';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { MatInputModule } from '@angular/material/input';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { ReactiveFormsModule } from '@angular/forms';
import { ItemService } from './item.service';
import { RoundProgressModule } from 'angular-svg-round-progressbar';
import { DOCUMENT } from '@angular/common';
import { TruncatePipe } from './pipes/truncate.pipe';

@NgModule({

  providers: [
    
  ],
  declarations: [
    AppComponent,
    TruncatePipe,
    TruncatePipe
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    HttpClientModule,
    FormsModule,
    BrowserAnimationsModule,
    MatInputModule,
    MatAutocompleteModule,
    ReactiveFormsModule,
    RoundProgressModule
  ],
 
  bootstrap: [AppComponent]
})
export class AppModule { }
