import s from "./--Name--s.module.scss";
import cn from "classnames";

import { useState, useEffect } from "react";

import { Section, SectionBaseProps } from "../../blocks/Section/Section";
import { ColorMode, TColorMode } from "../../blocks/ColorMode/ColorMode";
import { List } from "../../common/List/List";

import { --Name--, T--Name-- } from "./--Name--/--Name--";

interface --Name--sComponentProps {
	colorMode: TColorMode;

	--name--s: T--Name--[];
}

interface --Name--sProps extends SectionBaseProps {
	props: --Name--sComponentProps;
}

export const --Name--s: React.FC<--Name--sProps> = ({
	handlers,
	id,
	props,
	setProps,
}) => {
	const [colorMode, setColorMode] = useState(props.colorMode);
	const [--name--s, set--Name--s] = useState(props.--name--s);

	useEffect(() => {
		setProps((props) => ({
			type: props.type,
			colorMode,
			--name--s,
		}));
	}, [colorMode, --name--s]);

	return (
		<Section
			id={id}
			title="{You title}"
			handlers={handlers}
			parts={[
				<ColorMode value={colorMode} onChange={setColorMode} />,
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
