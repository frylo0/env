import s from "./--Name--.module.scss";
import cn from "classnames";

import { useState, useEffect } from "react";

import { Section, SectionBaseProps } from "../../blocks/Section/Section";
import { ColorMode, TColorMode } from "../../blocks/ColorMode/ColorMode";

interface --Name--ComponentProps {
	colorMode: TColorMode;
}

interface --Name--Props extends SectionBaseProps {
	props: --Name--ComponentProps;
}

export const --Name--: React.FC<--Name--Props> = ({
	handlers,
	id,
	props,
	setProps,
}) => {
	const [colorMode, setColorMode] = useState(props.colorMode);

	useEffect(() => {
		setProps((props) => ({
			type: props.type,
			colorMode,
		}));
	}, [colorMode]);

	return (
		<Section
			id={id}
			className={cn(s['--naMe--'])}
			title="{You title}"
			handlers={handlers}
			parts={[
				<ColorMode value={colorMode} onChange={setColorMode} />,
			]}
		/>
	);
};
