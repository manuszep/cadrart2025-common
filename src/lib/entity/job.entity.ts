import { ICadrartLocation } from './location.entity';
import { ICadrartTask } from './task.entity';
import { ICadrartOffer } from './offer.entity';
import { ICadrartApiEntity } from './base.entity';

export enum ECadrartJobOrientation {
  VERTICAL,
  HORIZONTAL
}

export enum ECadrartJobMeasureType {
  MEASURE_GLASS,
  MEASURE_EXTERIOR,
  MEASURE_APPROX,
  MEASURE_OPENING
}

export interface ICadrartJob extends ICadrartApiEntity {
  offer: ICadrartOffer;
  count: number;
  orientation: ECadrartJobOrientation;
  measure: ECadrartJobMeasureType;
  location?: ICadrartLocation;
  dueDate?: Date;
  startDate?: Date;
  openingWidth: number;
  openingHeight: number;
  marginWidth: number;
  marginHeight: number;
  glassWidth: number;
  glassHeight: number;
  tasks?: ICadrartTask[];
  description?: string;
  image?: string;
  total: number;
  totalBeforeReduction: number;
  totalWithVat: number;
}
