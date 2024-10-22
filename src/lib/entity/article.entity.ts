import { ICadrartApiEntity } from './base.entity';
import { ICadrartFormula } from './formula.entity';
import { ICadrartProvider } from './provider.entity';
import { ICadrartTask } from './task.entity';

export enum ECadrartArticlePriceMethod {
  BY_LENGTH,
  BY_AREA,
  BY_FIX_VALUE
}

export enum ECadrartArticleFamily {
  GLASS,
  WOOD,
  CARDBOARD,
  ASSEMBLY,
  PASS
}

export interface ICadrartArticle extends ICadrartApiEntity {
  name: string;
  place?: string;
  buyPrice?: number;
  sellPrice?: number;
  getPriceMethod: ECadrartArticlePriceMethod;
  family: ECadrartArticleFamily;
  maxReduction?: number;
  provider?: ICadrartProvider;
  formula?: ICadrartFormula;
  providerRef?: string;
  maxLength?: number;
  maxWidth?: number;
  combine: boolean;
  tasks?: ICadrartTask[];
}
