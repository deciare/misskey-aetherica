<template>
<MkSpacer :content-max="900">
	<div class="ogwlenmc">
		<div v-if="tab === 'local'" class="local">
			<MkInput v-model="query" :debounce="true" type="search">
				<template #prefix><i class="fas fa-search"></i></template>
				<template #label>{{ $ts.search }}</template>
			</MkInput>
			<MkSwitch v-model="selectMode" style="margin: 8px 0;">
				<template #label>Select mode</template>
			</MkSwitch>
			<div v-if="selectMode" style="display: flex; gap: var(--margin); flex-wrap: wrap;">
				<MkButton inline @click="selectAll">Select all</MkButton>
				<MkButton inline @click="setCategoryBulk">Set category</MkButton>
				<MkButton inline @click="addTagBulk">Add tag</MkButton>
				<MkButton inline @click="removeTagBulk">Remove tag</MkButton>
				<MkButton inline @click="setTagBulk">Set tag</MkButton>
				<MkButton inline danger @click="delBulk">Delete</MkButton>
			</div>
			<MkPagination ref="emojisPaginationComponent" :pagination="pagination">
				<template #empty><span>{{ $ts.noCustomEmojis }}</span></template>
				<template v-slot="{items}">
					<div class="ldhfsamy">
						<button v-for="emoji in items" :key="emoji.id" class="emoji _panel _button" :class="{ selected: selectedEmojis.includes(emoji.id) }" @click="selectMode ? toggleSelect(emoji) : edit(emoji)">
							<img :src="emoji.url" class="img" :alt="emoji.name"/>
							<div class="body">
								<div class="name _monospace">{{ emoji.name }}</div>
								<div class="info">{{ emoji.category }}</div>
							</div>
						</button>
					</div>
				</template>
			</MkPagination>
		</div>

		<div v-else-if="tab === 'remote'" class="remote">
			<FormSplit>
				<MkInput v-model="queryRemote" :debounce="true" type="search">
					<template #prefix><i class="fas fa-search"></i></template>
					<template #label>{{ $ts.search }}</template>
				</MkInput>
				<MkInput v-model="host" :debounce="true">
					<template #label>{{ $ts.host }}</template>
				</MkInput>
			</FormSplit>
			<MkPagination :pagination="remotePagination">
				<template #empty><span>{{ $ts.noCustomEmojis }}</span></template>
				<template v-slot="{items}">
					<div class="ldhfsamy">
						<div v-for="emoji in items" :key="emoji.id" class="emoji _panel _button" @click="remoteMenu(emoji, $event)">
							<img :src="emoji.url" class="img" :alt="emoji.name"/>
							<div class="body">
								<div class="name _monospace">{{ emoji.name }}</div>
								<div class="info">{{ emoji.host }}</div>
							</div>
						</div>
					</div>
				</template>
			</MkPagination>
		</div>
	</div>
</MkSpacer>
</template>

<script lang="ts" setup>
import { computed, defineAsyncComponent, defineComponent, ref, toRef } from 'vue';
import MkButton from '@/components/ui/button.vue';
import MkInput from '@/components/form/input.vue';
import MkPagination from '@/components/ui/pagination.vue';
import MkTab from '@/components/tab.vue';
import MkSwitch from '@/components/form/switch.vue';
import FormSplit from '@/components/form/split.vue';
import { selectFile, selectFiles } from '@/scripts/select-file';
import * as os from '@/os';
import * as symbols from '@/symbols';
import { i18n } from '@/i18n';

const emojisPaginationComponent = ref<InstanceType<typeof MkPagination>>();

const tab = ref('local');
const query = ref(null);
const queryRemote = ref(null);
const host = ref(null);
const selectMode = ref(false);
const selectedEmojis = ref<string[]>([]);

const pagination = {
	endpoint: 'admin/emoji/list' as const,
	limit: 30,
	params: computed(() => ({
		query: (query.value && query.value !== '') ? query.value : null,
	})),
};

const remotePagination = {
	endpoint: 'admin/emoji/list-remote' as const,
	limit: 30,
	params: computed(() => ({
		query: (queryRemote.value && queryRemote.value !== '') ? queryRemote.value : null,
		host: (host.value && host.value !== '') ? host.value : null,
	})),
};

const selectAll = () => {
	if (selectedEmojis.value.length > 0) {
		selectedEmojis.value = [];
	} else {
		selectedEmojis.value = emojisPaginationComponent.value.items.map(item => item.id);
	}
};

const toggleSelect = (emoji) => {
	if (selectedEmojis.value.includes(emoji.id)) {
		selectedEmojis.value = selectedEmojis.value.filter(x => x !== emoji.id);
	} else {
		selectedEmojis.value.push(emoji.id);
	}
};

const add = async (ev: MouseEvent) => {
	const files = await selectFiles(ev.currentTarget ?? ev.target, null);

	const promise = Promise.all(files.map(file => os.api('admin/emoji/add', {
		fileId: file.id,
	})));
	promise.then(() => {
		emojisPaginationComponent.value.reload();
	});
	os.promiseDialog(promise);
};

const edit = (emoji) => {
	os.popup(defineAsyncComponent(() => import('./emoji-edit-dialog.vue')), {
		emoji: emoji
	}, {
		done: result => {
			if (result.updated) {
				emojisPaginationComponent.value.updateItem(result.updated.id, (oldEmoji: any) => ({
					...oldEmoji,
					...result.updated
				}));
			} else if (result.deleted) {
				emojisPaginationComponent.value.removeItem((item) => item.id === emoji.id);
			}
		},
	}, 'closed');
};

const im = (emoji) => {
	os.apiWithDialog('admin/emoji/copy', {
		emojiId: emoji.id,
	});
};

const remoteMenu = (emoji, ev: MouseEvent) => {
	os.popupMenu([{
		type: 'label',
		text: ':' + emoji.name + ':',
	}, {
		text: i18n.ts.import,
		icon: 'fas fa-plus',
		action: () => { im(emoji) }
	}], ev.currentTarget ?? ev.target);
};

const menu = (ev: MouseEvent) => {
	os.popupMenu([{
		icon: 'fas fa-download',
		text: i18n.ts.export,
		action: async () => {
			os.api('export-custom-emojis', {
			})
			.then(() => {
				os.alert({
					type: 'info',
					text: i18n.ts.exportRequested,
				});
			}).catch((e) => {
				os.alert({
					type: 'error',
					text: e.message,
				});
			});
		}
	}, {
		icon: 'fas fa-upload',
		text: i18n.ts.import,
		action: async () => {
			const file = await selectFile(ev.currentTarget ?? ev.target);
			os.api('admin/emoji/import-zip', {
				fileId: file.id,
			})
			.then(() => {
				os.alert({
					type: 'info',
					text: i18n.ts.importRequested,
				});
			}).catch((e) => {
				os.alert({
					type: 'error',
					text: e.message,
				});
			});
		}
	}], ev.currentTarget ?? ev.target);
};

const setCategoryBulk = async () => {
	const { canceled, result } = await os.inputText({
		title: 'Category',
	});
	if (canceled) return;
	await os.apiWithDialog('admin/emoji/set-category-bulk', {
		ids: selectedEmojis.value,
		category: result,
	});
	emojisPaginationComponent.value.reload();
};

const addTagBulk = async () => {
	const { canceled, result } = await os.inputText({
		title: 'Tag',
	});
	if (canceled) return;
	await os.apiWithDialog('admin/emoji/add-aliases-bulk', {
		ids: selectedEmojis.value,
		aliases: result.split(' '),
	});
	emojisPaginationComponent.value.reload();
};

const removeTagBulk = async () => {
	const { canceled, result } = await os.inputText({
		title: 'Tag',
	});
	if (canceled) return;
	await os.apiWithDialog('admin/emoji/remove-aliases-bulk', {
		ids: selectedEmojis.value,
		aliases: result.split(' '),
	});
	emojisPaginationComponent.value.reload();
};

const setTagBulk = async () => {
	const { canceled, result } = await os.inputText({
		title: 'Tag',
	});
	if (canceled) return;
	await os.apiWithDialog('admin/emoji/set-aliases-bulk', {
		ids: selectedEmojis.value,
		aliases: result.split(' '),
	});
	emojisPaginationComponent.value.reload();
};

const delBulk = async () => {
	const { canceled } = await os.confirm({
		type: 'warning',
		text: i18n.ts.deleteConfirm,
	});
	if (canceled) return;
	await os.apiWithDialog('admin/emoji/delete-bulk', {
		ids: selectedEmojis.value,
	});
	emojisPaginationComponent.value.reload();
};

defineExpose({
	[symbols.PAGE_INFO]: computed(() => ({
		title: i18n.ts.customEmojis,
		icon: 'fas fa-laugh',
		bg: 'var(--bg)',
		actions: [{
			asFullButton: true,
			icon: 'fas fa-plus',
			text: i18n.ts.addEmoji,
			handler: add,
		}, {
			icon: 'fas fa-ellipsis-h',
			handler: menu,
		}],
		tabs: [{
			active: tab.value === 'local',
			title: i18n.ts.local,
			onClick: () => { tab.value = 'local'; },
		}, {
			active: tab.value === 'remote',
			title: i18n.ts.remote,
			onClick: () => { tab.value = 'remote'; },
		},]
	})),
});
</script>

<style lang="scss" scoped>
.ogwlenmc {
	> .local {
		.empty {
			margin: var(--margin);
		}
		
		.ldhfsamy {
			display: grid;
			grid-template-columns: repeat(auto-fill, minmax(190px, 1fr));
			grid-gap: 12px;
			margin: var(--margin) 0;
	
			> .emoji {
				display: flex;
				align-items: center;
				padding: 11px;
				text-align: left;
				border: solid 1px var(--panel);

				&:hover {
					border-color: var(--inputBorderHover);
				}

				&.selected {
					border-color: var(--accent);
				}

				> .img {
					width: 42px;
					height: 42px;
				}

				> .body {
					padding: 0 0 0 8px;
					white-space: nowrap;
					overflow: hidden;

					> .name {
						text-overflow: ellipsis;
						overflow: hidden;
					}

					> .info {
						opacity: 0.5;
						text-overflow: ellipsis;
						overflow: hidden;
					}
				}
			}
		}
	}

	> .remote {
		.empty {
			margin: var(--margin);
		}

		.ldhfsamy {
			display: grid;
			grid-template-columns: repeat(auto-fill, minmax(190px, 1fr));
			grid-gap: 12px;
			margin: var(--margin) 0;

			> .emoji {
				display: flex;
				align-items: center;
				padding: 12px;
				text-align: left;

				&:hover {
					color: var(--accent);
				}

				> .img {
					width: 32px;
					height: 32px;
				}

				> .body {
					padding: 0 0 0 8px;
					white-space: nowrap;
					overflow: hidden;

					> .name {
						text-overflow: ellipsis;
						overflow: hidden;
					}

					> .info {
						opacity: 0.5;
						font-size: 90%;
						text-overflow: ellipsis;
						overflow: hidden;
					}
				}
			}
		}
	}
}
</style>
