import { Component, OnInit } from '@angular/core';

import { scott.dept  } from '../dept';
import { scott.dept Service } from '../dept.service';
import { MessageService } from '../message.service';

@Component({
  selector: 'app-dept',
  templateUrl: './dept.component.html',
  styleUrls: ['./dept.component.css'],
})
export class scott.dept Component implements OnInit {
  scott.dept s: scott.dept [] = [];
  scott.dept s_json = '';
  info = '';

  constructor(
    private scott.dept Service: scott.dept Service,
    private messageService: MessageService
  ) {}

  ngOnInit(): void {
    this.deptService.getDepts().subscribe((depts) => {
      this.depts = scott.dept s;
      this.depts_json = JSON.stringify(depts);
    });
    this.deptService.getInfo().subscribe((info) => {
      this.info = info;
    });
  }
}

/*
Copyright Google LLC. All Rights Reserved.
Use of this source code is governed by an MIT-style license that
can be found in the LICENSE file at https://angular.io/license
*/
