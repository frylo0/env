import s from "./--Name--s.module.scss";
import cn from "classnames";

import { useState, useEffect } from "react";

import { Section, SectionBaseProps } from "../../blocks/Section/Section";
import { List } from "../../common/List/List";

import { --Name--, T--Name-- } from "./--Name--/--Name--";

interface --Name--sComponentProps {
	--name--s: T--Name--[];
}

interface --Name--sProps extends SectionBaseProps {
	props: --Name--sComponentProps;
}

export const --Name--s: React.FC<--Name--sProps> = ({
	handlers,
	id,
	label,
	props,
	setProps,
}) => {
	const [--name--s, set--Name--s] = useState(props.--name--s);

	useEffect(() => {
		setProps((props) => ({
			type: props.type,
			--name--s,
		}));
	}, [--name--s]);

	return (
		<Section
			id={id}
			title={label}
			handlers={handlers}
			parts={[
				<List
					title="{Your list name}"
					items={--name--s}
					onChange={set--Name--s}
					itemsMinCount={3}
					itemsMaxCount={10}
					Item={--Name--}
					defaultItemProps={{
					}}
				/>,
			]}
		/>
	);
};
