import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { UserService } from '../Services/user.service';
import Swal from 'sweetalert2';


@Component({
  selector: 'app-add',
  templateUrl: './add.component.html',
  styleUrls: ['./add.component.css']
})
export class AddComponent implements OnInit {

  constructor( private _user: UserService ,private router: Router){}
user={
  name: '',
  email: '',
  address: '',
  tel: ''
}





  ngOnInit(): void {}


add(){

    this._user.add( this.user ).subscribe({
      next: (res)=>{
        Swal.fire({
          position: 'top-end',
          icon: 'success',
          title: 'Your work has been saved',
          showConfirmButton: false,
          timer: 1500
        })

        this.router.navigate(['/home']);

      },
      error: (error)=>{
        Swal.fire({
          position: 'top-end',
          icon: 'error',
          title: 'Please try again!!',
          showConfirmButton: false,
          timer: 1500
        })

      }
    })

  }

  }


