import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class UserService {
  url = ' API_Gateway_Endpoint';
  constructor( private http: HttpClient ) { }
  add(user: any){
    return this.http.post( this.url + 'add' , user);
  }


  getAll( ){
    return this.http.get( this.url + 'getall' );
  }


  getById( name: any ){
    return this.http.get( this.url + 'getbyid/' + name );
  }

  delete( id: any ){
    return this.http.delete( this.url + 'delete/' + id );
}
}
