import { Component , OnInit } from '@angular/core';
import { UserService } from '../Services/user.service';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css']
})
export class HomeComponent implements OnInit{
name:any;
users:any;
  constructor(private user: UserService ) { }
  ngOnInit(): void {}

  search(name:any){
    this.user.getById(name).subscribe({
      next:(res)=>{
        this.users = res;
      },
      error: (err)=>{
        console.log(err);
      }
    });
  }
}


