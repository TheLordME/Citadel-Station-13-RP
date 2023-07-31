/**
 * @file
 * @license MIT
*/

import { Section } from "../../components";
import { SectionProps } from "../../components/Section";


//* Context

export type AtmosGasID = string;
export type AtmosGasIDs = AtmosGasID[];

export enum AtmosGasGroupFlags {
  None = (0),
  Core = (1<<0),
  Other = (1<<1),
  Unknown = (1<<2),
  Reagents = (1<<3),
}
export type AtmosGasGroups = AtmosGasGroupFlags;

export enum AtmosGasFlags {
  None = (0),
  Fuel = (1<<0),
  Oxidizer = (1<<1),
  Contaminent = (1<<2),
  FusionFuel = (1<<3),
  Unknown = (1<<4),
  Core = (1<<5),
  Filterable = (1<<6),
  Dangerous = (1<<7),
}

export const AtmosGroupFlagNames = [
  "Core",
  "Other",
  "Unknown",
  "Reagents",
];

interface BaseGasContext {
  coreGases: AtmosGasID[];
  groupNames: string[];
  filterableGases: AtmosGasID[];
  filterableGroups: AtmosGasGroups;
}

export interface GasContext extends BaseGasContext {
  gases: Record<AtmosGasID, AtmosGas>;
}

export interface FullGasContext extends BaseGasContext {
  gases: Record<AtmosGasID, FullAtmosGas>;
}

export interface AtmosGas {
  id: AtmosGasID;
  name: string;
  flags: AtmosGasFlags;
  groups: AtmosGasGroups;
  specificHeat: number;
  molarMass: number;
}

export interface FullAtmosGas extends AtmosGas {

}

//* Filtering

interface AtmosFilterListProps extends SectionProps {
  selectedGroups: AtmosGasGroups;
  selectedIds: AtmosGasIDs;
  selectGroup: (group: AtmosGasGroupFlags, filter: boolean) => void;
  selectId: (id: AtmosGasID, filter: boolean) => void;
}

export const AtmosFilterList = (props: AtmosFilterListProps) => {
  return (
    <Section {...props}>
      Test
    </Section>
  );
};

//* Tanks

export interface AtmosTank {
  name: string;
  // kpa
  pressure: number;
  // gauge limit, not actual cap/limit
  pressureLimit: number;
  // liters
  volume: number;
}
