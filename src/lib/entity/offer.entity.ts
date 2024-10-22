import { ICadrartTeamMember } from './team-member.entity';
import { ICadrartClient } from './client.entity';
import { ICadrartJob } from './job.entity';
import { ICadrartApiEntity } from './base.entity';

export enum ECadrartOfferStatus {
  STATUS_CREATED,
  STATUS_STARTED,
  STATUS_DONE
}

export interface ICadrartOffer extends ICadrartApiEntity {
  createdAt: Date;
  number: string;
  client?: ICadrartClient;
  assignedTo?: ICadrartTeamMember;
  status: ECadrartOfferStatus;
  adjustedReduction?: number;
  adjustedVat?: number;
  jobs: ICadrartJob[];
  total: number;
  totalBeforeReduction: number;
  totalWithVat: number;
}
