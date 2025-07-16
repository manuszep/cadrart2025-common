import { ICadrartTeamMember } from "./team-member.entity";
import { ICadrartClient } from "./client.entity";
import { ICadrartJob } from "./job.entity";
import { ICadrartApiEntity } from "./base.entity";

export enum ECadrartOfferStatus {
  STATUS_CREATED = "0",
  STATUS_STARTED = "1",
  STATUS_DONE = "2",
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
