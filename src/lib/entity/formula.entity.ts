import { ICadrartApiEntity } from './base.entity';

export interface ICadrartFormula extends ICadrartApiEntity {
  name: string;
  formula: string;
}
