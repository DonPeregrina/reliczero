import os
import io
import soundfile as sf
import sounddevice as sd
from dotenv import load_dotenv
load_dotenv()

ELEVENLABS_API_KEY = os.getenv('ELEVENLABS_API_KEY')
class ElevenSpeech: 
    def gen_dub(self, text):
        try:
            print("Generando audio...")
            client = ElevenLabs(api_key=ELEVENLABS_API_KEY)

            if not text.strip():
                return

            audio = client.generate(
                text=text,
                voice="Rachel",
                model="eleven_multilingual_v2"
            )
            audio_bytes = b"".join(audio)
            audio_io = io.BytesIO(audio_bytes)
            data, samplerate = sf.read(audio_io)
            sd.play(data, samplerate)
            sd.wait()
            print("Audio reproducido exitosamente")

        except Exception as e:
            print(f"Error generando/reproduciendo audio: {e}")

traducir = ElevenSpeech()
traducir.gen_dub("que onda carnal como ves lo que estuvo pasando ese dia")