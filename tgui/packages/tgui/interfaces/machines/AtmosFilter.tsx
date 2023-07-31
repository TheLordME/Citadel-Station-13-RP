//* This file is explicitly licensed under the MIT license. *//
//* Copyright (c) 2023 Citadel Station developers.          *//

import { useBackend } from "../../backend";
import { LabeledList, NumberInput } from "../../components";
import { Section, SectionProps } from "../../components/Section";
import { AtmosFilterList, AtmosGasGroups, AtmosGasID, AtmosGasGroupFlags, GasContext } from "../common/Atmos";
import { AtmosComponent, AtmosComponentData } from "../common/AtmosMachine";

interface AtmosFilterControlProps extends SectionProps {
  atmosContext: GasContext;
  filtering: null | AtmosGasGroups | AtmosGasID;
  setFiltering?: (target: AtmosGasGroups|AtmosGasID) => void;
}

export const AtmosFilterControl = (props: AtmosFilterControlProps, context) => {
  return (
    <Section title="Filter" {...props}>
      <AtmosFilterList
        selectedGroups={((typeof props.filtering) === 'number')? (props.filtering as number) : AtmosGasGroupFlags.None}
        selectedIds={((typeof props.filtering) === 'string')? ([props.filtering as string]) : []}
        selectGroup={(g) => props.setFiltering?.(g)}
        selectId={(id) => props.setFiltering?.(id)} />
    </Section>
  );
};

interface AtmosFilterData extends AtmosComponentData {
  atmosContext: GasContext;
  filtering: null | AtmosGasGroups | AtmosGasID;
  rate: number;
  maxRate: number;
}

export const AtmosFilter = (props, context) => {
  const { act, data } = useBackend<AtmosFilterData>(context);

  return (
    <AtmosComponent
      additionalListItems={(
        <LabeledList.Item label="Flow">
          <NumberInput minValue={0} maxValue={data.maxRate}
            value={data.rate} onChange={(e, val) => act('rate', { rate: val })} />
        </LabeledList.Item>
      )}>
      <AtmosFilterControl
        setFiltering={(target) => act('filter', { target: target })}
        atmosContext={data.atmosContext}
        filtering={data.filtering} />
    </AtmosComponent>
  );
};
