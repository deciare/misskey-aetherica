import * as fs from 'node:fs';
import * as tmp from 'tmp';
import { IImage, convertToJpeg } from './image-processor.js';
import FFmpeg from 'fluent-ffmpeg';

export async function GenerateVideoThumbnail(path: string): Promise<IImage> {
	const [outDir, cleanup] = await new Promise<[string, any]>((res, rej) => {
		tmp.dir((e, path, cleanup) => {
			if (e) return rej(e);
			res([path, cleanup]);
		});
	});

	await new Promise((res, rej) => {
		FFmpeg({
			source: path,
		})
		.on('end', res)
		.on('error', rej)
		.screenshot({
			folder: outDir,
			filename: 'output.png',
			count: 1,
			timestamps: ['5%'],
		});
	});

	const outPath = `${outDir}/output.png`;

	// JPEGに変換 (Webpでもいいが、MastodonはWebpをサポートせず表示できなくなる)
	const thumbnail = await convertToJpeg(outPath, 498, 280);

	// cleanup
	await fs.promises.unlink(outPath);
	cleanup();

	return thumbnail;
}
