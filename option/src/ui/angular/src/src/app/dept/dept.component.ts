import { Component, OnInit } from '@angular/core';

import { Dept } from '../dept';
import { DeptService } from '../dept.service';
import { MessageService } from '../message.service';

@Component({
  selector: 'app-dept',
  templateUrl: './dept.component.html',
  styleUrls: ['./dept.component.css'],
})
export class DeptComponent implements OnInit {
  depts: Dept[] = [];
  depts_json = '';
  info = '';

  constructor(
    private deptService: DeptService,
    private messageService: MessageService
  ) {}

  ngOnInit(): void {
    this.deptService.getDepts().subscribe((depts) => {
      this.depts = depts;
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
