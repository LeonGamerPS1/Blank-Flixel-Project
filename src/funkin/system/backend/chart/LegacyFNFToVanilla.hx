package funkin.system.backend.chart;

class LegacyFNFToVanilla
{
	public static function convert(legacyJson:moonchart.formats.fnf.legacy.FNFPsych):SongMap // legacy psych me idiot... 0.7.3 maybe
	{
		try
		{
			var output:SongMap = {
				displayName: legacyJson.data.song.song,
				songName: legacyJson.data.song.song,
				players: [
					legacyJson.data.song.player2,
					legacyJson.data.song.gfVersion,
					legacyJson.data.song.player1
				],
				composer: null,
				charter: null,
				bpmMap: [],

				bpm: legacyJson.data.song.bpm,
				speed: legacyJson.data.song.speed,
				tracks: {
					main: 'songs/${legacyJson.data.song.song}/Inst.ogg',
					extra: ['songs/${legacyJson.data.song.song}/Voices.ogg']
				},

				notes: [],
				events: []
			};

			var beatLength:Float =  60 / output.bpm;
			beatLength *= 1000;

			for (section in legacyJson.data.song.notes)
			{
				var sectionTime:Float = (beatLength * 4) * (legacyJson.data.song.notes.indexOf(section) + 1);
				if (section.changeBPM == true)
				{
					beatLength = 60 / output.bpm;
					beatLength *= 1000;
					sectionTime = (beatLength * 4) * (legacyJson.data.song.notes.indexOf(section) + 1);

					output.bpmMap.push({
						time: sectionTime,
						denominator: 4,
						numerator: 4,
						bpm: section.bpm
					});
				}

				output.events.push({
					time: sectionTime,
					name: "Camera Focus",
					values: [section.mustHitSection ? 'bf' : 'dad']
				});

				for (note in section.sectionNotes)
				{
					var mustHit = section.mustHitSection;
					if (note.lane > 3)
						mustHit = !section.mustHitSection;

					var data = note.lane % 4;
					var type = 'normal';

					if(section.altAnim)
						type = 'Alt Note';
					

					output.notes.push({
						time: note.time,
						data: mustHit ? data + 4 : data,
						length: note.length,
						type: type
					});
				}
			}

			return output;
		}
		catch (E)
		{
			throw E;
		}
	}
}
