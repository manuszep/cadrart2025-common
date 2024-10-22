import { ICadrartApiEntity } from './base.entity';
import { ICadrartClient } from './client.entity';

export interface ICadrartTag extends ICadrartApiEntity {
  name: string;
  clients: ICadrartClient[];
}
