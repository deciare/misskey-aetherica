<template>
<div class="yxspomdl" :class="{ inline, colored, mini }">
	<div class="container">
		<svg class="spinner bg" viewBox="0 0 168 168" xmlns="http://www.w3.org/2000/svg">
			<g transform="matrix(1.125,0,0,1.125,12,12)">
				<circle cx="64" cy="64" r="64" style="fill:none;stroke:currentColor;stroke-width:21.33px;"/>
			</g>
		</svg>
		<svg class="spinner fg" viewBox="0 0 168 168" xmlns="http://www.w3.org/2000/svg">
			<g transform="matrix(1.125,0,0,1.125,12,12)">
				<path d="M128,64C128,28.654 99.346,0 64,0C99.346,0 128,28.654 128,64Z" style="fill:none;stroke:currentColor;stroke-width:21.33px;"/>
			</g>
		</svg>
	</div>
</div>
</template>

<script lang="ts" setup>
import { } from 'vue';

const props = withDefaults(defineProps<{
	inline?: boolean;
	colored?: boolean;
	mini?: boolean;
}>(), {
	inline: false,
	colored: true,
	mini: false,
});
</script>

<style lang="scss" scoped>
@keyframes spinner {
	0% {
		transform: rotate(0deg);
	}
	100% {
		transform: rotate(360deg);
	}
}

.yxspomdl {
	padding: 32px;
	text-align: center;
	cursor: wait;

	--size: 40px;

	&.colored {
		color: var(--accent);
	}

	&.inline {
		display: inline;
		padding: 0;
		--size: 32px;
	}

	&.mini {
		padding: 16px;
		--size: 32px;
	}

	> .container {
		position: relative;
		width: var(--size);
		height: var(--size);
		margin: 0 auto;

		> .spinner {
			position: absolute;
			top: 0;
			left: 0;
			width: var(--size);
			height: var(--size);
			fill-rule: evenodd;
			clip-rule: evenodd;
			stroke-linecap: round;
			stroke-linejoin: round;
			stroke-miterlimit: 1.5;
		}

		> .bg {
			opacity: 0.275;
		}

		> .fg {
			animation: spinner 0.5s linear infinite;
		}
	}
}
</style>
