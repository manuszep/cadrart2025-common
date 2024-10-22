import { ICadrartApiEntity } from './base.entity';

export interface ICadrartExtendedTask extends ICadrartApiEntity {
  taskComment: string;
  taskTotal: number;
  taskImage: string;
  taskDoneCount: number;
  taskParentId: number;
  jobId: number;
  jobCount: number;
  jobOrientation: number;
  jobMeasure: number;
  jobDueDate: Date;
  jobStartDate: Date;
  jobOpeningWidth: number;
  jobOpeningHeight: number;
  jobMarginWidth: number;
  jobMarginHeight: number;
  jobGlassWidth: number;
  jobGlassHeight: number;
  jobDescription: string;
  jobImage: string;
  jobLocation: string;
  articleId: number;
  articleName: string;
  articlePlace: string;
  articleFamily: number;
  offerId: number;
  offerStatus: number;
  assignedToId: number;
  assignedToFirstName: string;
  assignedToLastName: string;
  clientId: number;
  clientFirstName: string;
  clientLastName: string;
}
