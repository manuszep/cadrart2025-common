import { ICadrartApiEntity } from './base.entity';
import { ICadrartJob } from './job.entity';

export interface ICadrartLocation extends ICadrartApiEntity {
  name: string;
  jobs?: ICadrartJob[];
}
