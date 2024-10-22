import { HttpStatus } from '@nestjs/common';

import { ICadrartApiEntity } from './entity';

export type ICadrartResponse = {
  statusCode: HttpStatus;
};

export type ICadrartEntityResponse<T> = {
  statusCode: HttpStatus;
  entity: T;
};

export type ICadrartEntitiesResponse<T> = {
  statusCode: HttpStatus;
  entities: T[];
  total: number;
};

export type ICadrartListOption = {
  label: string;
  value: number;
};

export type ICadrartEntityListOption = {
  statusCode: HttpStatus;
  entities: ICadrartListOption[];
};

export interface ICadrartSocketCreateEntity<T extends ICadrartApiEntity> {
  name: string;
  entity: T;
}

export interface ICadrartSocketUpdateEntity<T extends ICadrartApiEntity> {
  name: string;
  entity: T;
}

export interface ICadrartSocketDeleteEntity {
  name: string;
  id: number;
}
