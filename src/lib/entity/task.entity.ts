import { ICadrartArticle } from "./article.entity";
import { ICadrartApiEntity } from "./base.entity";
import { ICadrartJob } from "./job.entity";

export interface ICadrartTask extends ICadrartApiEntity {
  job: ICadrartJob;
  article: ICadrartArticle;
  comment?: string;
  total: number;
  totalBeforeReduction: number;
  totalWithVat: number;
  image?: string;
  children?: ICadrartTask[];
  parent?: ICadrartTask;
  doneCount: number;
}

export type ICadrartTaskLax = Partial<ICadrartTask> & {
  children?: ICadrartTaskLax[];
  parent?: ICadrartTaskLax;
};
