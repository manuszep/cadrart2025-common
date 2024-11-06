export type PartialDeep<T> = T extends (...args: any[]) => any
  ? T
  : T extends Date
  ? T
  : T extends Array<infer InferredArrayMember>
  ? Array<PartialDeep<InferredArrayMember>>
  : T extends object
  ? DeepPartialObject<T>
  : T | undefined;

type DeepPartialObject<T> = {
  [Key in keyof T]?: PartialDeep<T[Key]>;
};

export type NullableProps<T> = {
  [K in keyof T]: T[K] | null;
};

export type NullablePropsDeep<T> = {
  [K in keyof T]: T[K] extends (infer U)[]
    ? NullablePropsDeep<U>[] | null
    : T[K] | null;
};

export type List<A = any> = ReadonlyArray<A>;

export type Class<TC> = {
  new (...args: any): TC;
};
